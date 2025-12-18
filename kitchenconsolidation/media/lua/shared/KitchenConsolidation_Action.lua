-- KitchenConsolidation_Action.lua
-- Multi-yield consolidation action (base-hunger–scaled foods)
-- Build 41 authoritative implementation

require "TimedActions/ISBaseTimedAction"

local Util = require("KitchenConsolidation_Util")

KitchenConsolidation_Action = ISBaseTimedAction:derive("KitchenConsolidation_Action")

-- ---------------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------------

function KitchenConsolidation_Action:new(character, items)
    local o = ISBaseTimedAction.new(self, character)
    o.items = items or {}
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 30 + (#o.items * 10)
    return o
end

-- ---------------------------------------------------------------------------
-- Validation
-- ---------------------------------------------------------------------------

function KitchenConsolidation_Action:isValid()
    if not self.character then return false end

    local inv = self.character:getInventory()
    if not inv then return false end

    for _, item in ipairs(self.items) do
        if not inv:contains(item) then
            return false
        end
        if not Util.isEligibleFoodItem(item) then
            return false
        end
    end

    return true
end

-- ---------------------------------------------------------------------------
-- Timed action lifecycle
-- ---------------------------------------------------------------------------

function KitchenConsolidation_Action:start()
    self:setActionAnim("Loot")
    self.character:reportEvent("EventLootItem")
end

function KitchenConsolidation_Action:update()
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function KitchenConsolidation_Action:stop()
    ISBaseTimedAction.stop(self)
end

-- ---------------------------------------------------------------------------
-- Core merge logic (multi-yield)
-- ---------------------------------------------------------------------------

function KitchenConsolidation_Action:perform()
    Util.debug("=== KitchenConsolidation_Action:perform ===")

    local inv = self.character:getInventory()

    -- Snapshot sources
    local sources = {}
    for _, item in ipairs(self.items) do
        table.insert(sources, item)
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
        ISBaseTimedAction.perform(self)
        return
    end

    -- Compute aggregate yield from partial items only
    local fullCount, remainderFrac =
        Util.computeBaseHungerAggregateYield(partialItems)

    Util.debug(string.format(
        "Aggregate yield from partials: fullCount=%d remainderFrac=%.3f",
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

        Util.applyWorstCaseFreshness(sources, newItem)
        Util.applyWorstCaseSickness(sources, newItem)
        Util.applyCappedWeight(sources, newItem)

        -- Set hunger
        local baseHung = newItem:getBaseHunger()
        local newHung = baseHung * frac

        if newItem.setHungChange then
            newItem:setHungChange(newHung)
        elseif newItem.setHungerChange then
            newItem:setHungerChange(newHung)
        end

        -- Set thirst if applicable
        if newItem.getThirstChange and newItem.setThirstChange then
            local baseThirst = newItem:getThirstChange()
            if baseThirst then
                newItem:setThirstChange(baseThirst * frac)
            end
        end

        return newItem
    end

    -- Spawn full items
    for i = 1, fullCount do
        Util.debug("Spawning FULL item")
        spawnItemWithFraction(1.0)
    end

    -- Spawn remainder item (if any)
    if remainderFrac > Util.EPS then
        Util.debug(string.format(
            "Spawning PARTIAL item frac=%.3f",
            remainderFrac
        ))
        spawnItemWithFraction(remainderFrac)
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

    Util.debug("=== KitchenConsolidation_Action:perform END ===")

    ISBaseTimedAction.perform(self)
end

return KitchenConsolidation_Action