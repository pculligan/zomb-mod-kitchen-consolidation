-- KitchenConsolidation_Items_Containerized.lua
-- Phase 1 containerized fungible foods
-- Items that produce a container byproduct when fully consumed

local Items = {}

-- Items eligible for merging
Items.WHITELIST = {
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
Items.BYPRODUCT_ON_EMPTY = {
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

return Items
