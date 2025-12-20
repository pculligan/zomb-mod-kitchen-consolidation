-- KitchenConsolidation_ConsolidateAction.lua
-- Multi-yield consolidation action for fungible prepared foods and containers
-- Build 41 authoritative implementation

require "TimedActions/ISBaseTimedAction"

local Util = require("KitchenConsolidation_Util")

ConsolidateAction =
    ISBaseTimedAction:derive("ConsolidateAction")

-- ---------------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------------

function ConsolidateAction:new(character, items)
    local o = ISBaseTimedAction.new(self, character)

    if type(items) ~= "table" then
        Util.warn("ConsolidateAction:new received non-table items; coercing to empty table")
        o.items = {}
    else
        o.items = items
    end

    o.stopOnWalk = true
    o.stopOnRun = true

    local count = 0
    for _ in ipairs(o.items) do count = count + 1 end
    o.maxTime = 30 + (count * 10)

    return o
end

-- ---------------------------------------------------------------------------
-- Validation
-- ---------------------------------------------------------------------------

function ConsolidateAction:isValid()
    if not self.character then return false end

    local inv = self.character:getInventory()
    if not inv then return false end

    for _, item in ipairs(self.items) do
        if not inv:contains(item) then
            Util.debug("isValid: item no longer in inventory: " .. tostring(item))
            return false
        end
        if not Util.isEligibleFoodItem(item) then
            Util.debug(
                "isValid: item not eligible for consolidation: " ..
                tostring(item:getFullType())
            )
            return false
        end
    end

    -- Enforce bucket strictness at action-level (explicit, freshness-aware)
    if #self.items > 1 then
        local first = self.items[1]
        local refState = Util.getMergeState(first)

        Util.logMergeState("isValid:first", first)

        for i = 2, #self.items do
            local cur = self.items[i]
            Util.logMergeState("isValid:compare", cur)

            local s = Util.getMergeState(cur)

            if s.fullType ~= refState.fullType then
                Util.warn("isValid: type mismatch")
                return false
            end
            if s.cooked ~= refState.cooked then
                Util.warn("isValid: cooked/raw mismatch")
                return false
            end
            if s.burnt ~= refState.burnt then
                Util.warn("isValid: burnt state mismatch")
                return false
            end
            if s.freshness ~= refState.freshness then
                Util.warn("isValid: freshness bucket mismatch")
                return false
            end
        end
    end

    return true
end

-- ---------------------------------------------------------------------------
-- Timed action lifecycle
-- ---------------------------------------------------------------------------

function ConsolidateAction:start()
    self:setActionAnim("Loot")
    self.character:reportEvent("EventLootItem")
end

function ConsolidateAction:update()
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function ConsolidateAction:stop()
    ISBaseTimedAction.stop(self)
end

-- ---------------------------------------------------------------------------
-- Core merge logic (multi-yield)
-- ---------------------------------------------------------------------------

function ConsolidateAction:perform()

    local inv = self.character:getInventory()

    -- Snapshot sources
    local sources = {}
    for _, item in ipairs(self.items) do
        table.insert(sources, item)
    end

    -- Defensive freshness-aware enforcement (MP safety)
    if #sources > 1 then
        local refState = Util.getMergeState(sources[1])
        Util.logMergeState("perform:first", sources[1])

        for i = 2, #sources do
            local s = Util.getMergeState(sources[i])
            Util.logMergeState("perform:compare", sources[i])

            if s.fullType ~= refState.fullType
                or s.cooked ~= refState.cooked
                or s.burnt ~= refState.burnt
                or s.freshness ~= refState.freshness
            then
                Util.warn("perform: merge invariant violation; aborting consolidate")
                ISBaseTimedAction.perform(self)
                return
            end
        end
    end

    Util.debug("Source items:")
    for i, item in ipairs(sources) do
        Util.debug(string.format(
            "  src[%d] %s frac=%.3f",
            i,
            tostring(item:getFullType()),
            tonumber(Util.computeFraction(item)) or -1
        ))
    end

    if #sources == 0 then
        ISBaseTimedAction.perform(self)
        return
    end

    -- Partition sources into full vs partial
    local fullItems = {}
    local partialItems = {}

    for _, item in ipairs(sources) do
        local frac = Util.computeFraction(item)
        if frac and frac >= (1.0 - Util.EPS) then
            table.insert(fullItems, item)
        else
            table.insert(partialItems, item)
        end
    end

    Util.debug(string.format(
        "Partitioned: full=%d partial=%d",
        #fullItems,
        #partialItems
    ))

    -- Nothing to merge if there are no partial items
    if #partialItems == 0 then
        Util.debug("No partial items; nothing to consolidate")
        ISBaseTimedAction.perform(self)
        return
    end

    -- Compute aggregate yield from partial items using KC_FullHunger
    local total = 0
    local capacity = partialItems[1]:getModData().KC_FullHunger

    for _, item in ipairs(partialItems) do
        local cur = Util.getCurrentHunger(item)
        if cur then
            total = total + math.abs(cur)
        end
    end

    local fullCount = math.floor(total / capacity)
    local remainderFrac = (total - (fullCount * capacity)) / capacity

    Util.debug(string.format(
        "Aggregate yield from partials: total=%.3f capacity=%.3f fullCount=%d remainderFrac=%.3f",
        total,
        capacity,
        fullCount,
        remainderFrac
    ))

    local outputsCreated = fullCount
    if remainderFrac > Util.EPS then
        outputsCreated = outputsCreated + 1
    end

    local partialConsumed = #partialItems
    local byproductUnits = partialConsumed - outputsCreated
    if byproductUnits < 0 then byproductUnits = 0 end

    Util.debug(string.format(
        "Counts: partialConsumed=%d outputsCreated=%d byproductUnits=%d",
        partialConsumed,
        outputsCreated,
        byproductUnits
    ))

    if fullCount <= 0 and remainderFrac <= Util.EPS then
        Util.debug("Aggregate yield is zero; aborting consolidation")
        ISBaseTimedAction.perform(self)
        return
    end

    -- Canonical template item (used only for cloning)
    local template = partialItems[1]
    local fullType = template:getFullType()

    -- Helper to spawn a new food item with given fraction
    local function spawnItemWithFraction(frac)
        local newItem = inv:AddItem(fullType)
        if not newItem then return end

        -- Propagate canonical KC_FullHunger from template
        local md = newItem:getModData()
        md.KC_FullHunger = template:getModData().KC_FullHunger

        Util.debug(
            "spawnItemWithFraction: propagated KC_FullHunger=" ..
            tostring(md.KC_FullHunger)
        )

        Util.applyWorstCaseFreshness(sources, newItem)
        Util.applyWorstCaseSickness(sources, newItem)
        Util.applyCappedWeight(sources, newItem)

        local full = md.KC_FullHunger

        Util.debug("spawnItemWithFraction: full=" .. tostring(full) .. " frac=" .. tostring(frac))

        if not full or full <= Util.EPS then
            Util.warn("spawnItemWithFraction: missing KC_FullHunger; refusing")
            inv:Remove(newItem)
            return nil
        end

        -- Hunger sign: edible food must have negative HungChange (reduces hunger)
        local newHung = -math.abs(full * frac)
        Util.debug("spawnItemWithFraction: setting hunger=" .. tostring(newHung))
        Util.setCurrentHunger(newItem, newHung)

        -- Set thirst if applicable
        if newItem.getThirstChange and newItem.setThirstChange then
            local baseThirst = newItem:getThirstChange()
            if baseThirst then
                newItem:setThirstChange(baseThirst * frac)
            end
        end

        if newItem.updateAge then
            newItem:updateAge()
        end

        -- Log summary of output item
        local age = (newItem.getAge and newItem:getAge()) or "nil"
        local offAge = (newItem.getOffAge and newItem:getOffAge()) or "nil"
        local offAgeMax = (newItem.getOffAgeMax and newItem:getOffAgeMax()) or "nil"

        Util.debug(string.format(
            "Consolidated output: fullType=%s fraction=%.3f age=%s offAge=%s offAgeMax=%s",
            tostring(fullType),
            frac,
            tostring(age),
            tostring(offAge),
            tostring(offAgeMax)
        ))

        return newItem
    end

    -- Spawn full items
    for i = 1, fullCount do
        Util.debug("Spawning FULL item")
        if not spawnItemWithFraction(1.0) then
            Util.warn("WARNING: failed to spawn FULL consolidated item")
        end
    end

    -- Spawn remainder item (if any)
    if remainderFrac > Util.EPS then
        Util.debug(string.format(
            "Spawning PARTIAL item frac=%.3f",
            remainderFrac
        ))
        if not spawnItemWithFraction(remainderFrac) then
            Util.warn("WARNING: failed to spawn PARTIAL consolidated item")
        end
    end

    -- Remove consumed partial items
    for _, item in ipairs(partialItems) do
        Util.debug("Removing partial item: " .. tostring(item:getFullType()))
        inv:Remove(item)
    end

    -- Emit byproducts using arithmetic (consumed - produced)
    if byproductUnits > 0 then
        local bp = Util.getByproductForEmptiedItem(template)

        Util.debug("Emitting byproducts from template: " .. tostring(template:getFullType()))
        Util.debug("Byproduct units to emit: " .. tostring(byproductUnits))

        if bp then
            for i = 1, byproductUnits do
                if type(bp) == "table" then
                    for _, ft in ipairs(bp) do
                        Util.debug("  Emitting byproduct: " .. tostring(ft))
                        inv:AddItem(ft)
                    end
                else
                    Util.debug("  Emitting byproduct: " .. tostring(bp))
                    inv:AddItem(bp)
                end
            end
        end
    else
        Util.debug("byproductUnits == 0; emitting none")
    end

    Util.debug("=== ConsolidateAction:perform END ===")

    ISBaseTimedAction.perform(self)
end

return ConsolidateAction