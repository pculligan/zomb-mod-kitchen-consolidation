-- Phase 1 containerized and fungible foods

local Containerized = {}

-- Items eligible for merging
Containerized.WHITELIST = {
    -- Opened canned foods (tin can byproduct)
    ["Base.OpenBeans"] = true,
    ["Base.CannedCarrotsOpen"] = true,
    ["Base.CannedChiliOpen"] = true,
    ["Base.CannedCornOpen"] = true,
    ["Base.CannedCornedBeefOpen"] = true,
    ["Base.DogfoodOpen"] = true,
    ["Base.CannedMilkOpen"] = true,
    ["Base.CannedFruitBeverageOpen"] = true,
    ["Base.CannedFruitCocktailOpen"] = true,
    ["Base.CannedMushroomSoupOpen"] = true,
    ["Base.CannedPeachesOpen"] = true,
    ["Base.CannedPeasOpen"] = true,
    ["Base.CannedPineappleOpen"] = true,
    ["Base.CannedPotatoOpen"] = true,
    ["Base.CannedSardinesOpen"] = true,
    ["Base.CannedBologneseOpen"] = true,
    ["Base.CannedTomatoOpen"] = true,
    ["Base.TunaTinOpen"] = true,
    ["Base.TinnedSoupOpen"] = true,

    -- Opened jarred foods (jar byproduct)
    ["Base.CannedBellPepper_Open"] = true,
    ["Base.CannedBroccoli_Open"] = true,
    ["Base.CannedCabbage_Open"] = true,
    ["Base.CannedCarrots_Open"] = true,
    ["Base.CannedEggplant_Open"] = true,
    ["Base.CannedLeek_Open"] = true,
    ["Base.CannedPotato_Open"] = true,
    ["Base.CannedRedRadish_Open"] = true,
    ["Base.CannedTomato_Open"] = true,
    ["Base.CannedRoe_Open"] = true,

    -- Dry bulk ingredients with sack byproduct
    ["Base.Flour2"] = true,
    ["Base.Cornmeal2"] = true,
    ["Base.Cornflour2"] = true,

    -- Sauces and condiments in jars
    ["Base.Marinara"] = true,
    ["Base.Soysauce"] = true,
    ["Base.Pickles"] = true,

    -- Oils and vinegars in bottles
    ["Base.OilOlive"] = true,
    ["Base.OilVegetable"] = true,
    ["Base.SesameOil"] = true,
    ["Base.Vinegar"] = true,
    ["Base.RiceVinegar"] = true,

    -- Paste containers
    ["Base.TomatoPaste"] = true,
}

-- Container byproducts spawned when an item is fully consumed
Containerized.BYPRODUCT_ON_EMPTY = {
    -- Tin cans
    ["Base.OpenBeans"] = "Base.TinCanEmpty",
    ["Base.CannedCarrotsOpen"] = "Base.TinCanEmpty",
    ["Base.CannedChiliOpen"] = "Base.TinCanEmpty",
    ["Base.CannedCornOpen"] = "Base.TinCanEmpty",
    ["Base.CannedCornedBeefOpen"] = "Base.TinCanEmpty",
    ["Base.DogfoodOpen"] = "Base.TinCanEmpty",
    ["Base.CannedMilkOpen"] = "Base.TinCanEmpty",
    ["Base.CannedFruitBeverageOpen"] = "Base.TinCanEmpty",
    ["Base.CannedFruitCocktailOpen"] = "Base.TinCanEmpty",
    ["Base.CannedMushroomSoupOpen"] = "Base.TinCanEmpty",
    ["Base.CannedPeachesOpen"] = "Base.TinCanEmpty",
    ["Base.CannedPeasOpen"] = "Base.TinCanEmpty",
    ["Base.CannedPineappleOpen"] = "Base.TinCanEmpty",
    ["Base.CannedPotatoOpen"] = "Base.TinCanEmpty",
    ["Base.CannedSardinesOpen"] = "Base.TinCanEmpty",
    ["Base.CannedBologneseOpen"] = "Base.TinCanEmpty",
    ["Base.CannedTomatoOpen"] = "Base.TinCanEmpty",
    ["Base.TunaTinOpen"] = "Base.TinCanEmpty",
    ["Base.TinnedSoupOpen"] = "Base.TinCanEmpty",

    -- Jars
    ["Base.CannedBellPepper_Open"] = { "Base.EmptyJar", "Base.JarLid" },
    ["Base.CannedBroccoli_Open"] = { "Base.EmptyJar", "Base.JarLid" },
    ["Base.CannedCabbage_Open"] = { "Base.EmptyJar", "Base.JarLid" },
    ["Base.CannedCarrots_Open"] = { "Base.EmptyJar", "Base.JarLid" },
    ["Base.CannedEggplant_Open"] = { "Base.EmptyJar", "Base.JarLid" },
    ["Base.CannedLeek_Open"] = { "Base.EmptyJar", "Base.JarLid" },
    ["Base.CannedPotato_Open"] = { "Base.EmptyJar", "Base.JarLid" },
    ["Base.CannedRedRadish_Open"] = { "Base.EmptyJar", "Base.JarLid" },
    ["Base.CannedTomato_Open"] = { "Base.EmptyJar", "Base.JarLid" },
    ["Base.CannedRoe_Open"] = { "Base.EmptyJar", "Base.JarLid" },

    -- Sacks
    ["Base.Flour2"] = "Base.WheatSack",
    ["Base.Cornmeal2"] = "Base.WheatSack",
    ["Base.Cornflour2"] = "Base.WheatSack",

    -- Jars
    ["Base.Marinara"] = { "Base.EmptyJar", "Base.JarLid" },
    ["Base.Soysauce"] = { "Base.EmptyJar", "Base.JarLid" },

    -- Bottles (screw-top)
    ["Base.OilOlive"] = "Base.WineScrewtop",
    ["Base.OilVegetable"] = "Base.WineScrewtop",
    ["Base.SesameOil"] = "Base.WineScrewtop",
    ["Base.Vinegar"] = "Base.WineScrewtop",
    ["Base.RiceVinegar"] = "Base.WineScrewtop",

    -- Aluminum units
    ["Base.TomatoPaste"] = "Base.Aluminum",
}

local Fungible = {}

Fungible.WHITELIST = {
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

return Containerized, Fungible
