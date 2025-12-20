local Vanilla = require("KitchenConsolidation_PrepMap_Vanilla")
local hasFoodPreservationPlus, FoodPreservationPlus =
    pcall(require, "KitchenConsolidation_PrepMap_FoodPreservationPlus")
local hasCookingTime, CookingTime =
    pcall(require, "KitchenConsolidation_PrepMap_CookingTime")

local PrepMap = {}

local function mergeInto(target, source)
    for k, v in pairs(source or {}) do
        target[k] = v
    end
end

mergeInto(PrepMap,Vanilla)

if hasFoodPreservationPlus and FoodPreservationPlus then
    mergeInto(PrepMap, FoodPreservationPlus)
end
if hasCookingTime and CookingTime then
    mergeInto(PrepMap, CookingTime)
end

return PrepMap
