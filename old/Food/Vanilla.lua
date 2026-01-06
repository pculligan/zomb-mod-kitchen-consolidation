local FoodType = require "core/domain/FoodType"


local FoodVanilla = {

    -- Opened canned foods (tin can byproduct)
    FoodType.new({
        fullType = "Base.OpenBeans",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.CannedCarrotsOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.CannedChiliOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.CannedCornOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.CannedCornedBeefOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.DogfoodOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.CannedMilkOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.CannedFruitBeverageOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.CannedFruitCocktailOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.CannedMushroomSoupOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.CannedPeachesOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.CannedPeasOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.CannedPineappleOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.CannedPotatoOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.CannedSardinesOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.CannedBologneseOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.CannedTomatoOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.TunaTinOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),
    FoodType.new({
        fullType = "Base.TinnedSoupOpen",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.TinCanEmpty" }
    }),

    -- Opened jarred foods (jar byproduct)
    FoodType.new({
        fullType = "Base.CannedBellPepper_Open",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.EmptyJar", "Base.JarLid" }
    }),
    FoodType.new({
        fullType = "Base.CannedBroccoli_Open",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.EmptyJar", "Base.JarLid" }
    }),
    FoodType.new({
        fullType = "Base.CannedCabbage_Open",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.EmptyJar", "Base.JarLid" }
    }),
    FoodType.new({
        fullType = "Base.CannedCarrots_Open",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.EmptyJar", "Base.JarLid" }
    }),
    FoodType.new({
        fullType = "Base.CannedEggplant_Open",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.EmptyJar", "Base.JarLid" }
    }),
    FoodType.new({
        fullType = "Base.CannedLeek_Open",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.EmptyJar", "Base.JarLid" }
    }),
    FoodType.new({
        fullType = "Base.CannedPotato_Open",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.EmptyJar", "Base.JarLid" }
    }),
    FoodType.new({
        fullType = "Base.CannedRedRadish_Open",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.EmptyJar", "Base.JarLid" }
    }),
    FoodType.new({
        fullType = "Base.CannedTomato_Open",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.EmptyJar", "Base.JarLid" }
    }),
    FoodType.new({
        fullType = "Base.CannedRoe_Open",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.EmptyJar", "Base.JarLid" }
    }),

    -- Dry bulk ingredients with sack byproduct
    FoodType.new({
        fullType = "Base.Flour2",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.WheatSack" }
    }),
    FoodType.new({
        fullType = "Base.Cornmeal2",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.WheatSack" }
    }),
    FoodType.new({
        fullType = "Base.Cornflour2",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.WheatSack" }
    }),

    -- Sauces and condiments in jars
    FoodType.new({
        fullType = "Base.Marinara",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.EmptyJar", "Base.JarLid" }
    }),
    FoodType.new({
        fullType = "Base.Soysauce",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.EmptyJar", "Base.JarLid" }
    }),
    FoodType.new({
        fullType = "Base.Pickles",
        isContainerized = true
    }),

    -- Oils and vinegars in bottles
    FoodType.new({
        fullType = "Base.OilOlive",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.WineScrewtop" }
    }),
    FoodType.new({
        fullType = "Base.OilVegetable",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.WineScrewtop" }
    }),
    FoodType.new({
        fullType = "Base.SesameOil",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.WineScrewtop" }
    }),
    FoodType.new({
        fullType = "Base.Vinegar",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.WineScrewtop" }
    }),
    FoodType.new({
        fullType = "Base.RiceVinegar",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.WineScrewtop" }
    }),

    -- Paste containers
    FoodType.new({
        fullType = "Base.TomatoPaste",
        isContainerized = true, 
        byproductsOnEmpty = { "Base.Aluminum" }
    }),

    -- Fungible foods (containerized, no byproducts)
    FoodType.new({
        fullType = "Base.Blackbeans",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.DriedBlackBeans",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.DriedChickpeas",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.DriedKidneyBeans",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.DriedLentils",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.DriedSplitPeas",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.DriedWhiteBeans",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.SoybeansSeed",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Soybeans",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Salt",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.SeasoningSalt",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Sugar",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.SugarBrown",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.SugarPacket",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.SugarCubes",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Honey",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.MapleSyrup",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.PowderedGarlic",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.PowderedOnion",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Pepper",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.CornFrozen",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Peas",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.MixedVegetables",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Seasoning_Basil",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Seasoning_Chives",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Seasoning_Cilantro",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Seasoning_Oregano",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Seasoning_Parsley",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Seasoning_Rosemary",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Seasoning_Sage",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Seasoning_Thyme",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.OatsRaw",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Cereal",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.CocoaPowder",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Coffee2",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.JamFruit",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.PeanutButter",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.TortillaChips",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Crisps",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Crisps2",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Crisps3",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Crisps4",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.CatFoodBag",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.DogFoodBag",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Ramen",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Macaroni",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Pasta",
        isContainerized = true
    }),
    FoodType.new({
        fullType = "Base.Rice",
        isContainerized = true
    }),

    -- Prep-capable meat items
    FoodType.new({
        fullType = "Base.Bacon",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.BaconRashers",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.Baloney",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.BaloneySlice",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.Beef",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.BeefJerky",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.MeatPatty",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.ChickenWhole",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.ChickenFillet",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.Chicken",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.ChickenNuggets",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.ChickenWings",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.MincedMeat",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.Ham",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.HamSlice",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.Hotdog_single",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.MuttonChop",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.HotdogPack",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.Pepperoni",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.Pork",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.PorkChop",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.Salami",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.SalamiSlice",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.Sausage",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.Steak",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.TurkeyWhole",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.TurkeyFillet",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.TurkeyLegs",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.TurkeyWings",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.Venison",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.Rabbitmeat",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.Smallbirdmeat",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.Smallanimalmeat",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),
    FoodType.new({
        fullType = "Base.FrogMeat",
        prepTo = "KitchenConsolidation.MeatPieces"
    }),

    -- Prep-capable fish items
    FoodType.new({
        fullType = "Base.FishFillet",
        prepTo = "KitchenConsolidation.FishPieces"
    }),
    FoodType.new({
        fullType = "Base.SmallFishFillet",
        prepTo = "KitchenConsolidation.FishPieces"
    }),

    -- Prep-capable vegetable items
    FoodType.new({
        fullType = "Base.Avocado",
        prepTo = "KitchenConsolidation.AvocadoPieces"
    }),
    FoodType.new({
        fullType = "Base.BellPepper",
        prepTo = "KitchenConsolidation.BellPepperPieces"
    }),
    FoodType.new({
        fullType = "Base.Celery",
        prepTo = "KitchenConsolidation.CeleryPieces"
    }),
    FoodType.new({
        fullType = "Base.Cucumber",
        prepTo = "KitchenConsolidation.CucumberPieces"
    }),
    FoodType.new({
        fullType = "Base.Broccoli",
        prepTo = "KitchenConsolidation.BroccoliPieces"
    }),
    FoodType.new({
        fullType = "Base.Carrots",
        prepTo = "KitchenConsolidation.CarrotPieces"
    }),
    FoodType.new({
        fullType = "Base.Corn",
        prepTo = "KitchenConsolidation.CornPieces"
    }),
    FoodType.new({
        fullType = "Base.Daikon",
        prepTo = "KitchenConsolidation.DaikonPieces"
    }),
    FoodType.new({
        fullType = "Base.Eggplant",
        prepTo = "KitchenConsolidation.EggplantPieces"
    }),
    FoodType.new({
        fullType = "Base.PepperHabanero",
        prepTo = "KitchenConsolidation.PepperHabaneroPieces"
    }),
    FoodType.new({
        fullType = "Base.PepperJalapeno",
        prepTo = "KitchenConsolidation.PepperJalapenoPieces"
    }),
    FoodType.new({
        fullType = "Base.Leek",
        prepTo = "KitchenConsolidation.LeekPieces"
    }),
    FoodType.new({
        fullType = "Base.Lettuce",
        prepTo = "KitchenConsolidation.LettucePieces"
    }),
    FoodType.new({
        fullType = "Base.MushroomGeneric1",
        prepTo = "KitchenConsolidation.MushroomGenericPieces"
    }),
    FoodType.new({
        fullType = "Base.MushroomGeneric2",
        prepTo = "KitchenConsolidation.MushroomGenericPieces"
    }),
    FoodType.new({
        fullType = "Base.MushroomGeneric3",
        prepTo = "KitchenConsolidation.MushroomGenericPieces"
    }),
    FoodType.new({
        fullType = "Base.MushroomGeneric4",
        prepTo = "KitchenConsolidation.MushroomGenericPieces"
    }),
    FoodType.new({
        fullType = "Base.MushroomGeneric5",
        prepTo = "KitchenConsolidation.MushroomGenericPieces"
    }),
    FoodType.new({
        fullType = "Base.MushroomGeneric6",
        prepTo = "KitchenConsolidation.MushroomGenericPieces"
    }),
    FoodType.new({
        fullType = "Base.MushroomGeneric7",
        prepTo = "KitchenConsolidation.MushroomGenericPieces"
    }),
    FoodType.new({
        fullType = "Base.Onion",
        prepTo = "KitchenConsolidation.OnionPieces"
    }),
    FoodType.new({
        fullType = "Base.Seaweed",
        prepTo = "KitchenConsolidation.SeaweedPieces"
    }),
    FoodType.new({
        fullType = "Base.Zucchini",
        prepTo = "KitchenConsolidation.ZucchiniPieces"
    }),
    FoodType.new({
        fullType = "farming.Cabbage",
        prepTo = "KitchenConsolidation.CabbagePieces"
    }),
    FoodType.new({
        fullType = "farming.Potato",
        prepTo = "KitchenConsolidation.PotatoPieces"
    }),
    FoodType.new({
        fullType = "farming.RedRadish",
        prepTo = "KitchenConsolidation.RedRadishPieces"
    }),
    FoodType.new({
        fullType = "farming.Tomato",
        prepTo = "KitchenConsolidation.TomatoPieces"
    }),
    FoodType.new({
        fullType = "Base.Tofu",
        prepTo = "KitchenConsolidation.TofuPieces"
    }),
}

return FoodVanilla