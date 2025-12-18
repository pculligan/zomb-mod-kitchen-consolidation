-- KitchenConsolidation_Items.lua
-- Aggregates all Phase 1 item definitions into executable tables

local Containerized = require("KitchenConsolidation_Items_Containerized")
local Bulk = require("KitchenConsolidation_Items_FungibleBulk")
local hasCookingTime, CookingTime = pcall(require, "KitchenConsolidation_Items_CookingTime")

local Items = {}

Items.MERGEABLE_WHITELIST = {}
Items.BYPRODUCT_ON_EMPTY = {}

local function mergeInto(target, source)
    for k, v in pairs(source or {}) do
        target[k] = v
    end
end

mergeInto(Items.MERGEABLE_WHITELIST, Containerized.WHITELIST)
mergeInto(Items.MERGEABLE_WHITELIST, Bulk.WHITELIST)
mergeInto(Items.BYPRODUCT_ON_EMPTY, Containerized.BYPRODUCT_ON_EMPTY)

if hasCookingTime and CookingTime then
    -- Containerized CookingTime items
    mergeInto(Items.MERGEABLE_WHITELIST, CookingTime.WHITELIST)
    mergeInto(Items.BYPRODUCT_ON_EMPTY, CookingTime.BYPRODUCT_ON_EMPTY)

    -- Fungible bulk CookingTime items
    mergeInto(Items.MERGEABLE_WHITELIST, CookingTime.FUNGIBLE_BULK)
end

return Items
