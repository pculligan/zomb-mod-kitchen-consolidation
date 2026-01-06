
--[[
INVARIANTS:
  - FoodInstance is an immutable value object after construction.
  - All engine access must go through Engine layer helpers.
  - No Lua type() checks on engine objects.
]]

local Runtime = require("infra/Runtime")
local assured = Runtime.Guard.assured
local failOn = Runtime.Guard.failOn
local warnOn = Runtime.Guard.warnOn
local debug = Runtime.Logger.debug
local trace = Runtime.Logger.trace


local Optional = Runtime.Optional


local FoodRegistry = require("core/domain/FoodRegistry")
local Registry = FoodRegistry.instance

local Engine = require("Engine/Engine")
local Item = Engine.Item
local ItemWeight = Engine.ItemWeight
local ItemFood = Engine.ItemFood
local Inventory = Engine.Inventory

local PrepResult = require("core/domain/PrepResult")

local FoodInstance = {}

-- ---------------------------------------------------------------------------
-- Prep eligibility (domain-owned)
-- ---------------------------------------------------------------------------

-- True if this instance is eligible to be prepped (has prepTo and positive hunger)
function FoodInstance:canPrep()
    return self.type ~= nil
        and self.type.prepTo ~= nil
        and (self.hunger or 0) < 0
end

-- True if this instance is eligible to be prepped specifically to the given target fullType
function FoodInstance:canPrepTo(targetFullType)
    return self:canPrep() and self.type.prepTo == targetFullType
end


-- Returns true if this FoodInstance is full (cannot be combined further)
function FoodInstance:isFull()
    return self.hunger >= (self.type.maxHunger - 0.0001)
end

-- Returns true if this FoodInstance can be combined with another (same type and not full)
function FoodInstance:canCombineWith(other)
    if not other or not other.type or not self.type then return false end
    if self:isFull() or other:isFull() then return false end
    return self.type.fullType == other.type.fullType and self.type.isContainerized and other.type.isContainerized
end


-- FoodInstance is an immutable value object.
-- All fields are snapshots captured at construction time.
function FoodInstance.new(args)
    local inst = {
        type   = args.type,
        hunger = args.hunger,
    }
    setmetatable(inst, { __index = FoodInstance })
    return inst
end


-- fromItem is the ONLY place where engine state is read.
-- After construction, FoodInstance is immutable and engine-independent.
function FoodInstance.fromItem(item)
    -- Diagnostic: prove we accept userdata (Project Zomboid InventoryItem/Food)
    trace("FoodInstance.fromItem ENTER item=" .. tostring(item))

    if failOn(item == nil, "FoodInstance.fromItem called with nil item") then
        return nil
    end

    -- Per engine-api.md:
    -- Do NOT classify by Lua type (userdata is expected)
    -- Only require minimal identity access
    if warnOn(item.getFullType == nil or type(item.getFullType) ~= "function",
        "FoodInstance.fromItem SKIP: item missing getFullType()"
    ) then
        return nil
    end

    -- Optional food classification: if IsFood exists, respect it; otherwise do not assume
    if item.IsFood ~= nil and type(item.IsFood) == "function" and not item:IsFood() then
        warnOn(true, "FoodInstance.fromItem SKIP: item.IsFood() == false for " .. tostring(item:getFullType()))
        return nil
    end

    local fullType = item:getFullType()
    if warnOn(fullType == nil,
        "FoodInstance.fromItem SKIP: getFullType() returned nil for item " .. tostring(item)
    ) then
        return nil
    end

    if warnOn(not Registry:has(fullType),
        "FoodInstance.fromItem SKIP: FoodType not in registry: " .. tostring(fullType)
    ) then
        return nil
    end

    local foodType = Registry:get(fullType)
    if failOn(foodType == nil,
        "FoodInstance.fromItem invariant violated: registry has() true but get() nil for " .. tostring(fullType)
    ) then
        return nil
    end

    trace("FoodInstance.fromItem BUILDING domain object for " .. fullType)

    -- Diagnostic: units comparison between engine and registry
    trace(string.format(
        "FoodInstance.fromItem DIAG units: fullType=%s registry.maxHunger=%s",
        tostring(fullType), tostring(foodType and foodType.maxHunger)
    ))

    -- Pull minimal engine-facing values via the engine layer.
    -- IMPORTANT: Do not probe additional engine properties here (poison/sickness/boredom/unhappy/weight/etc).
    local engineHunger = ItemFood.getHunger(item)
    trace("FoodInstance.fromItem DIAG: raw engine hunger getter returned=" .. tostring(engineHunger) .. " for " .. tostring(fullType))
    if type(engineHunger) == "number" then
        trace(string.format(
            "engineHunger=%s",
            engineHunger)
        )
    end
    local hunger = engineHunger
    trace("FoodInstance.fromItem DIAG hunger: " .. tostring(hunger) .. " for " .. tostring(fullType))

    local inst = FoodInstance.new{
        type = foodType,
        hunger = hunger,
    }
    debug("FoodInstance.fromItem RETURN " .. FoodInstance.debugDump(inst))
    return inst
end



function FoodInstance.canPrepItems(items)
    local groups = {}
    for _, item in ipairs(items or {}) do
        if item and item.getFullType then
            local fullType = item:getFullType()
            if Registry and Registry:has(fullType) then
                local inst = FoodInstance.fromItem(item)
                if inst and inst:canPrep() then
                    local target = inst.type.prepTo
                    if target then
                        groups[target] = groups[target] or {}
                        table.insert(groups[target], item)
                    end
                else
                    debug("FoodInstance.canPrepItems: item cannot be prepped: " .. tostring(fullType))
                end
            else
                debug("FoodInstance.canPrepItems: item type not in registry: " .. tostring(fullType))
            end
        end
    end
    return groups
end

-- Compute byproducts from sources and outputs.
-- Rule: containerized sources may "reuse" their container if the produced output is also containerized.
-- We emit byproducts ONLY for containers that become empty after the operation.
--
-- Examples:
--   - 2x full cans -> 2x outputs that are also containerized -> 0 empties
--   - 2x full cans -> 1x output can + 1x non-container output -> 1 empty can
--   - 8x partial cans -> repack into 1x full can -> 7 empty cans
--
-- Domain-level helper: no engine access, no mutation.
local function computeByproductsFromSources(sourceInstances, producedInstances)
    sourceInstances = sourceInstances or {}
    producedInstances = producedInstances or {}

    local byproducts = {}

    -- Count containerized sources and containerized produced outputs.
    local sourceContainers = 0
    for _, src in ipairs(sourceInstances) do
        local t = src and src.type
        if t and t.isContainerized then
            sourceContainers = sourceContainers + 1
        end
    end

    local producedContainers = 0
    for _, out in ipairs(producedInstances) do
        local t = out and out.type
        if t and t.isContainerized then
            producedContainers = producedContainers + 1
        end
    end

    local empties = sourceContainers - producedContainers
    if empties < 0 then empties = 0 end

    if empties == 0 then
        return byproducts
    end

    local remaining = empties
    for _, src in ipairs(sourceInstances) do
        if remaining <= 0 then break end
        local t = src and src.type
        if t and t.isContainerized and t.byproducts then
            for _, bypFullType in ipairs(t.byproducts) do
                table.insert(byproducts, bypFullType)
            end
            remaining = remaining - 1
        end
    end

    return byproducts
end

local function repackFood(fullType, contributionItems)
    debug(string.format("repackFood: called with %d contributionItems", #contributionItems))

    if not assured(type(contributionItems) == "table" and #contributionItems > 0, "repackFood: contributionItems must be a non-empty array") then return nil end

    -- Guard: if all contributionItems are full, warn and return nil
    local allFull = true
    for _, item in ipairs(contributionItems) do
        if not item:isFull() then
            allFull = false
            break
        end
    end
    if allFull then
        warnOn(true, "repackFood: all contributionItems are full, nothing to create")
        return nil
    end

    local foodType = Registry:get(fullType)
    if not assured(foodType, "repackFood: unknown FoodType for fullType: " .. tostring(fullType)) then return nil end

    local totalHunger = 0
    for _, item in ipairs(contributionItems) do
        local ch = math.abs(item.hunger)
        totalHunger = totalHunger + ch
    end

    if not assured(totalHunger > 0, "repackFood: total hunger must be greater than 0") then return nil end

    debug(string.format("repackFood: totalHunger=%.2f, maxHunger=%d", totalHunger, foodType.maxHunger))

    local pieces = {}

    local fullPiecesCount = math.floor(totalHunger / foodType.maxHunger)
    local remainder = totalHunger - fullPiecesCount * foodType.maxHunger

    for i = 1, fullPiecesCount do
        local piece = FoodInstance.new{
            type = foodType,
            hunger = foodType.maxHunger,
        }
        if assured(piece, "repackFood: failed to create full piece " .. tostring(i)) then
            table.insert(pieces, piece)
            debug(string.format("repackFood: created full piece %d with hunger %.2f", i, foodType.maxHunger))
        end
    end

    if remainder > 0 then
        local partialPiece = FoodInstance.new{
            type = foodType,
            hunger = remainder,
        }
        if assured(partialPiece, "repackFood: failed to create partial piece") then
            table.insert(pieces, partialPiece)
            debug(string.format("repackFood: created partial piece with hunger %.2f", remainder))
        end
    end

    failOn(#pieces == 0, "repackFood: no pieces created, unexpected condition")
    return pieces
end

-- Consolidates multiple FoodInstances of the same type into 1..N FoodInstances.
-- This is the single authoritative consolidation entry point for the domain.
function FoodInstance.consolidate(contributionItems)
    debug(string.format(
        "FoodInstance.consolidate: called with %d items",
        type(contributionItems) == "table" and #contributionItems or -1
    ))

    -- Validate input array
    if not assured(type(contributionItems) == "table" and #contributionItems >= 2, "FoodInstance.consolidate: requires at least 2 FoodInstances") then return nil end

    -- Filter out full items
    local nonFull = {}
    for _, item in ipairs(contributionItems) do
        if not item:isFull() then
            table.insert(nonFull, item)
        end
    end
    if #nonFull < 2 then
        debug("FoodInstance.consolidate: fewer than 2 non-full instances, skipping consolidation")
        return nil
    end

    -- Validate same FoodType
    local fullType = nonFull[1].type.fullType
    for i = 2, #nonFull do
        if not assured(nonFull[i].type.fullType == fullType, "FoodInstance.consolidate: mixed FoodTypes not allowed") then return nil end
    end


    debug(string.format("FoodInstance.consolidate: dispatching to repackFood for type %s", fullType))

    -- Delegate all math and construction to repackFood
    local packedFood = repackFood(fullType, nonFull)

    if not packedFood or #packedFood == 0 then
        return nil
    end

    -- Byproducts: compute proportionally to how much of each source is consumed (always packedFood here)
    local byproducts = computeByproductsFromSources(nonFull, packedFood)

    -- Wrap consolidation output in a PrepResult for consistency with Prepare
    return PrepResult.new{
        produced = packedFood,
        byproducts = byproducts,
    }
end

-- Materializes this FoodInstance into the given ItemContainer.
-- This is the ONLY place that engine InventoryItem mutation should occur.
function FoodInstance:addToInventory(container)
    debug("FoodInstance.addToInventory ENTER for " .. FoodInstance.debugDump(self))

    if not assured(container and container.AddItem, "FoodInstance.addToInventory: invalid container " .. tostring(container)) then
        return nil
    end
    if not assured(self.type and self.type.fullType, "FoodInstance.addToInventory: missing FoodType/fullType on FoodInstance") then
        return nil
    end

    -- Create item via engine inventory shim
    local item = Inventory.add(container, self.type.fullType)
    if not assured(item ~= nil, "FoodInstance.addToInventory: Inventory.add failed for " .. tostring(self.type.fullType)) then
        return nil
    end

        -- Apply runtime hunger via engine shim (round‑trip, no math)
    if self.hunger ~= nil then
        ItemFood.setHunger(item, self.hunger)
    end
    -- -- Apply runtime weight via engine shim (no probing, no math)
    -- if self.type.weight ~= nil then
    --     ItemWeight.set(item, self.type.weight)
    -- end



    return item
end

-- Returns a short string summary of the domain object for debugging.
function FoodInstance.debugDump(domain)
    if not domain then
        return "<nil domain>"
    end
    return string.format(
        "FoodInstance{fullType=%s, ,hunger=%.2f}",
        domain.type and domain.type.fullType or "nil",
        domain.hunger or -10000000
    )
end


-- Executes a SINGLE preparation step on this FoodInstance.
-- Consumes the entire source FoodInstance and emits produced outputs and byproducts.
-- Caller is responsible for deleting the source item.
-- Returns a PrepResult table:
-- {
--   produced = { FoodInstance, ... },   -- 0..N outputs
--   byproducts = { FoodInstance, ... }, -- optional, may be empty
-- }
function FoodInstance:prepStep()
    debug("FoodInstance.prepStep ENTER for " .. tostring(self.type and self.type.fullType))

    if not assured(self.type, "FoodInstance.prepStep: missing type on FoodInstance") then return PrepResult.new{ produced = {}, byproducts = {} } end

    if not assured(self.type.prepTo ~= nil, "FoodInstance.prepStep: missing prepTo on FoodInstance.type (prepTo=nil)") then
        return PrepResult.new{ produced = {}, byproducts = {} }
    end

    local targetType = Registry:get(self.type.prepTo)
    if not assured(targetType, "FoodInstance.prepStep: prepTo FoodType not found in registry: " .. tostring(self.type.prepTo)) then return PrepResult.new{ produced = {}, byproducts = {} } end

    local totalHunger = self.hunger or 0
    if not assured(totalHunger < 0, "FoodInstance.prepStep: hunger >= 0, nothing to produce") then return PrepResult.new{ produced = {}, byproducts = {} } end


    local produced = {}
    local fullCount = math.floor(totalHunger / -targetType.maxHunger)
    local partialHunger = totalHunger % -targetType.maxHunger

    debug(string.format(
        "FoodInstance.prepStep: targetType=%s totalHunger=%.2f targetType.maxHunger=%s fullCount=%d partialHunger=%.2f",
        tostring(targetType and targetType.fullType),
        totalHunger,
        tostring(targetType and targetType.maxHunger),
        fullCount,
        partialHunger
    ))

    -- Full outputs
    for i = 1, fullCount do
        local out = FoodInstance.new{
            type = targetType,
            hunger = -targetType.maxHunger,
        }
        table.insert(produced, out)
        debug("FoodInstance.prepStep: created full output #" .. i)
    end

    -- Partial output if any
    if partialHunger > 0 then
        local partialOut = FoodInstance.new{
            type = targetType,
            hunger = -partialHunger,
        }
        table.insert(produced, partialOut)
        debug("FoodInstance.prepStep: created partial output with hunger " .. tostring(partialHunger))
    end

    -- Byproducts are always emitted because the source is always fully consumed
    local byproducts = computeByproductsFromSources({ self }, produced)

    debug("FoodInstance.prepStep EXIT produced=" .. #produced)

    return PrepResult.new{
        produced = produced,
        byproducts = byproducts,
    }
end

return FoodInstance

