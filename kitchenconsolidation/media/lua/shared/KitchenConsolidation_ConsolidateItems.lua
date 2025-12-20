-- KitchenConsolidation_ConsolidateItems.lua
-- Aggregates all consolidation-eligible items and byproduct rules.
-- This module MUST always return a table with the expected shape.

local Items = {
    MERGEABLE_WHITELIST = {},
    BYPRODUCT_ON_EMPTY  = {},
    FUNGIBLE_BULK       = {},
}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function mergeBoolMap(dst, src)
    if not src then return end
    for k, v in pairs(src) do
        if v then dst[k] = true end
    end
end

local function mergeValueMap(dst, src)
    if not src then return end
    for k, v in pairs(src) do
        dst[k] = v
    end
end

-- ---------------------------------------------------------------------------
-- Vanilla consolidation items
-- ---------------------------------------------------------------------------

do
    local ok, vanilla = pcall(require, "KitchenConsolidation_ConsolidateItems_Vanilla")
    if ok and vanilla then
        mergeBoolMap(Items.MERGEABLE_WHITELIST, vanilla.MERGEABLE_WHITELIST or vanilla.WHITELIST)
        mergeValueMap(Items.BYPRODUCT_ON_EMPTY,  vanilla.BYPRODUCT_ON_EMPTY)
        mergeBoolMap(Items.MERGEABLE_WHITELIST, vanilla.FUNGIBLE_BULK)
    end
end

-- ---------------------------------------------------------------------------
-- Cooking Time compatibility (optional)
-- ---------------------------------------------------------------------------

do
    local ok, ct = pcall(require, "KitchenConsolidation_ConsolidateItems_CookingTime")
    if ok and ct then
        mergeBoolMap(Items.MERGEABLE_WHITELIST, ct.MERGEABLE_WHITELIST or ct.WHITELIST)
        mergeValueMap(Items.BYPRODUCT_ON_EMPTY,  ct.BYPRODUCT_ON_EMPTY)
        mergeBoolMap(Items.MERGEABLE_WHITELIST, ct.FUNGIBLE_BULK)
    end
end

-- ---------------------------------------------------------------------------
-- Food Preservation Plus compatibility (optional)
-- ---------------------------------------------------------------------------

do
    local ok, fpp = pcall(require, "KitchenConsolidation_ConsolidateItems_FoodPreservationPlus")
    if ok and fpp then
        mergeBoolMap(Items.MERGEABLE_WHITELIST, fpp.MERGEABLE_WHITELIST or fpp.WHITELIST)
        mergeValueMap(Items.BYPRODUCT_ON_EMPTY,  fpp.BYPRODUCT_ON_EMPTY)
        mergeBoolMap(Items.MERGEABLE_WHITELIST, fpp.FUNGIBLE_BULK)
    end
end

return Items
