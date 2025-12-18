
local MeatsVanilla = {
    -- Start small; expand after validation
    ["Base.Bacon"] = true,
    ["Base.BaconRashers"] = true,
    ["Base.Baloney"] = true,
    ["Base.BaloneySlice"] = true,
    ["Base.Beef"] = true,
    ["Base.BeefJerky"] = true,
    ["Base.MeatPatty"] = true,
    ["Base.ChickenWhole"] = true,
    ["Base.ChickenFillet"] = true,
    ["Base.Chicken"] = true,
    ["Base.ChickenNuggets"] = true,
    ["Base.ChickenWings"] = true,
    ["Base.MincedMeat"] = true,
    ["Base.Ham"] = true,
    ["Base.HamSlice"] = true,
    ["Base.Hotdog_single"] = true,
    ["Base.MuttonChop"] = true,
    ["Base.HotdogPack"] = true,
    ["Base.Pepperoni"] = true,
    ["Base.Pork"] = true,
    ["Base.PorkChop"] = true,
    ["Base.Salami"] = true,
    ["Base.SalamiSlice"] = true,
    ["Base.Sausage"] = true,
    ["Base.Steak"] = true,
    ["Base.TurkeyWhole"] = true,
    ["Base.TurkeyFillet"] = true,
    ["Base.TurkeyLegs"] = true,
    ["Base.TurkeyWings"] = true,
    ["Base.Venison"] = true,
    ["Base.Rabbitmeat"] = true,
    ["Base.Smallbirdmeat"] = true,
    ["Base.Smallanimalmeat"] = true,
    ["Base.FrogMeat"] = true,
}

local hasCookingTime, CookingTime = pcall("KitchenConsolidation_Meats_CookingTime")
local hasFoodPreservationPlus, FoodPreservationPlus = pcall("KitchenConsolidation_Meats_FoodPreservationPlus")

local Meats = {}
Meats.SOURCES = {}
Meats.BYPRODUCT_ON_EMPTY = {}

local function mergeInto(target, source)
    for k, v in pairs(source or {}) do
        target[k] = v
    end
end

mergeInto(Meats.SOURCES, MeatsVanilla)

if hasCookingTime and CookingTime then
    -- Containerized CookingTime items
    mergeInto(Meats.SOURCES, CookingTime.SOURCES)
    mergeInto(Meats.BYPRODUCT_ON_EMPTY, CookingTime.BYPRODUCT_ON_EMPTY)
end

if hasFoodPreservationPlus and FoodPreservationPlus then
    -- Containerized FoodPreservationPlus items
    mergeInto(Meats.SOURCES, FoodPreservationPlus.SOURCES)
    mergeInto(Meats.BYPRODUCT_ON_EMPTY, FoodPreservationPlus.BYPRODUCT_ON_EMPTY)
end

return Meats