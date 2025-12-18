-- KitchenConsolidation_Items_FungibleBulk.lua
-- Phase 1 fungible bulk foods
-- Items that do NOT produce a container byproduct

local Items = {}

Items.WHITELIST = {
    -- Dried legumes & staples
    ["Base.Blackbeans"] = true,
    ["Base.DriedBlackBeans"] = true,
    ["Base.DriedChickpeas"] = true,
    ["Base.DriedKidneyBeans"] = true,
    ["Base.DriedLentils"] = true,
    ["Base.DriedSplitPeas"] = true,
    ["Base.DriedWhiteBeans"] = true,
    ["Base.SoybeansSeed"] = true,
    ["Base.Soybeans"] = true,

    -- Processed bulk ingredients & seasonings
    ["Base.Salt"] = true,
    ["Base.SeasoningSalt"] = true,
    ["Base.Sugar"] = true,
    ["Base.SugarBrown"] = true,
    ["Base.SugarPacket"] = true,
    ["Base.SugarCubes"] = true,
    ["Base.Honey"] = true,
    ["Base.MapleSyrup"] = true,
    ["Base.PowderedGarlic"] = true,
    ["Base.PowderedOnion"] = true,
    ["Base.Pepper"] = true,

    -- Frozen / packaged vegetables
    ["Base.CornFrozen"] = true,
    ["Base.Peas"] = true,
    ["Base.MixedVegetables"] = true,

    -- Seasonings (explicit seasoning items only)
    ["Base.Seasoning_Basil"] = true,
    ["Base.Seasoning_Chives"] = true,
    ["Base.Seasoning_Cilantro"] = true,
    ["Base.Seasoning_Oregano"] = true,
    ["Base.Seasoning_Parsley"] = true,
    ["Base.Seasoning_Rosemary"] = true,
    ["Base.Seasoning_Sage"] = true,
    ["Base.Seasoning_Thyme"] = true,

    -- Dry staples, spreads, snack bags, and feeds
    ["Base.OatsRaw"] = true,
    ["Base.Cereal"] = true,
    ["Base.CocoaPowder"] = true,
    ["Base.Coffee2"] = true,
    ["Base.JamFruit"] = true,
    ["Base.PeanutButter"] = true,
    ["Base.TortillaChips"] = true,
    ["Base.Crisps"] = true,
    ["Base.Crisps2"] = true,
    ["Base.Crisps3"] = true,
    ["Base.Crisps4"] = true,
    ["Base.CatFoodBag"] = true,
    ["Base.DogFoodBag"] = true,

    -- Dry grains, pasta, and noodles
    ["Base.Ramen"] = true,
    ["Base.Macaroni"] = true,
    ["Base.Pasta"] = true,
    ["Base.Rice"] = true,
}

return Items
