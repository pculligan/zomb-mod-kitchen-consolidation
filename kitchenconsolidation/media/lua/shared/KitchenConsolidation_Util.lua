-- KitchenConsolidation_Util.lua
-- Shared deterministic utility functions
-- Authoritative for Phase 1 behavior
-- See mod-spec.md: Design and Architecture / Core Functions

local KitchenConsolidation_Util = {}

-- ---------------------------------------------------------------------------
-- Debug logging (toggleable)
-- ---------------------------------------------------------------------------

KitchenConsolidation_Util.DEBUG = false

function KitchenConsolidation_Util.debug(msg)
    if KitchenConsolidation_Util.DEBUG then
        print("[KitchenConsolidation] " .. tostring(msg))
    end
end

local Items = require("KitchenConsolidation_Items")

-- ---------------------------------------------------------------------------
-- Constants / Configuration
-- ---------------------------------------------------------------------------

-- Epsilon for floating-point comparisons
KitchenConsolidation_Util.EPS = 0.0001

KitchenConsolidation_Util.MERGEABLE_WHITELIST = Items.MERGEABLE_WHITELIST
KitchenConsolidation_Util.BYPRODUCT_ON_EMPTY = Items.BYPRODUCT_ON_EMPTY

-- ---------------------------------------------------------------------------
-- Eligibility & Quantity
-- ---------------------------------------------------------------------------

function KitchenConsolidation_Util.computeFraction(item)
    if not instanceof(item, "Food") then return nil end

    local base = math.abs(item:getBaseHunger() or 0)
    if base <= 0 then return nil end

    local cur = math.abs(item:getHungerChange() or 0)
    local frac = cur / base

    return frac
end

-- ---------------------------------------------------------------------------
-- Quantity aggregation (multi-yield support)
-- ---------------------------------------------------------------------------

-- Computes aggregate yield for foods whose "full unit" is defined by
-- getBaseHunger() (e.g., canned goods, dry staples, spices).
--
-- This model assumes:
--   • Hunger fraction is authoritative
--   • Nutrition scales from base hunger
--   • All items share the same base hunger (same fullType)
--
-- NOT appropriate for:
--   • Meats
--   • Cook-state-dependent foods
--   • Foods whose nutrition does not scale linearly with hunger
--
-- Returns:
--   fullCount (integer >= 0)
--   remainderFrac (number in range [0, 1))
function KitchenConsolidation_Util.computeBaseHungerAggregateYield(sourceItems)
    if not sourceItems or #sourceItems == 0 then
        return 0, 0
    end

    -- Canonical "full" unit is derived from the first item
    local first = sourceItems[1]
    if not instanceof(first, "Food") then
        return 0, 0
    end

    local base = math.abs(first:getBaseHunger() or 0)
    if base <= 0 then
        return 0, 0
    end

    -- Sum total remaining amount across all source items
    local totalRemaining = 0

    for _, item in ipairs(sourceItems) do
        if instanceof(item, "Food") then
            local cur = math.abs(item:getHungerChange() or 0)
            if cur > 0 then
                totalRemaining = totalRemaining + cur
            end
        end
    end

    if totalRemaining <= 0 then
        return 0, 0
    end

    -- Compute how many full items we can yield
    local fullCount = math.floor(totalRemaining / base)

    -- Compute remainder as a fraction of a full item
    local remainder = totalRemaining - (fullCount * base)
    local remainderFrac = remainder / base

    -- Clamp for numerical safety
    if remainderFrac < KitchenConsolidation_Util.EPS then
        remainderFrac = 0
    end

    if remainderFrac >= (1.0 - KitchenConsolidation_Util.EPS) then
        fullCount = fullCount + 1
        remainderFrac = 0
    end

    return fullCount, remainderFrac
end

function KitchenConsolidation_Util.isEligibleFoodItem(item)
    if not instanceof(item, "Food") then return false end

    local fullType = item:getFullType()
    if not KitchenConsolidation_Util.MERGEABLE_WHITELIST[fullType] then
        return false
    end

    if item:isRotten() then return false end

    local frac = KitchenConsolidation_Util.computeFraction(item)
    if not frac then return false end

    return (frac > KitchenConsolidation_Util.EPS)
       and (frac < (1.0 - KitchenConsolidation_Util.EPS))
end

-- ---------------------------------------------------------------------------
-- Grouping
-- ---------------------------------------------------------------------------

function KitchenConsolidation_Util.buildMergeKey(item)
    -- Group by fullType + cooked + burnt (Phase 1 strictness)
    local cooked = false
    local burnt = false

    if item.isCooked then
        cooked = item:isCooked()
    end

    if item.isBurnt then
        burnt = item:isBurnt()
    end

    return table.concat({
        item:getFullType(),
        cooked and "cooked" or "raw",
        burnt and "burnt" or "ok"
    }, "|")
end

function KitchenConsolidation_Util.buildMergeGroups(items)
    local groups = {}

    for _, item in ipairs(items) do
        if KitchenConsolidation_Util.isEligibleFoodItem(item) then
            local key = KitchenConsolidation_Util.buildMergeKey(item)
            groups[key] = groups[key] or {}
            table.insert(groups[key], item)
        end
    end

    return groups
end

-- ---------------------------------------------------------------------------
-- Worst-Case State Application
-- ---------------------------------------------------------------------------

function KitchenConsolidation_Util.applyWorstCaseFreshness(sourceItems, resultItem)
    if not resultItem or not sourceItems then return end
    if not resultItem.getAge then return end

    local worstAge = 0
    local offAge = nil
    local offAgeMax = nil

    for _, item in ipairs(sourceItems) do
        if item.getAge then
            worstAge = math.max(worstAge, item:getAge())
        end
        if item.getOffAge then
            offAge = offAge and math.min(offAge, item:getOffAge()) or item:getOffAge()
        end
        if item.getOffAgeMax then
            offAgeMax = offAgeMax and math.min(offAgeMax, item:getOffAgeMax()) or item:getOffAgeMax()
        end
    end

    if resultItem.setAge then
        resultItem:setAge(worstAge)
    end
    if offAge and resultItem.setOffAge then
        resultItem:setOffAge(offAge)
    end
    if offAgeMax and resultItem.setOffAgeMax then
        resultItem:setOffAgeMax(offAgeMax)
    end
end

function KitchenConsolidation_Util.applyWorstCaseSickness(sourceItems, resultItem)
    if not resultItem or not sourceItems then return end

    local poisoned = false
    local tainted = false

    for _, item in ipairs(sourceItems) do
        if item.isPoisoned and item:isPoisoned() then
            poisoned = true
        end
        if item.isTainted and item:isTainted() then
            tainted = true
        end
    end

    if poisoned and resultItem.setPoisoned then
        resultItem:setPoisoned(true)
    end
    if tainted and resultItem.setTainted then
        resultItem:setTainted(true)
    end
end

-- ---------------------------------------------------------------------------
-- Weight & Nutrition
-- ---------------------------------------------------------------------------

function KitchenConsolidation_Util.applyCappedWeight(sourceItems, resultItem)
    if not resultItem or not sourceItems then return end
    if not resultItem.getActualWeight or not resultItem.setWeight then return end

    local totalWeight = 0
    local fullWeight = resultItem:getActualWeight()
    if not fullWeight then return end

    for _, item in ipairs(sourceItems) do
        local frac = KitchenConsolidation_Util.computeFraction(item)
        if frac and item.getActualWeight then
            totalWeight = totalWeight + (item:getActualWeight() * frac)
        end
    end

    local finalWeight = math.min(totalWeight, fullWeight)
    resultItem:setWeight(finalWeight)
end

-- ---------------------------------------------------------------------------
-- Empty Container Accounting
-- ---------------------------------------------------------------------------

function KitchenConsolidation_Util.getByproductForEmptiedItem(item)
    if not item then return nil end
    return KitchenConsolidation_Util.BYPRODUCT_ON_EMPTY[item:getFullType()]
end

return KitchenConsolidation_Util
