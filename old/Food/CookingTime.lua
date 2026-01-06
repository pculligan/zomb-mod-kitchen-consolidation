-- Domain/Food_CookingTime.lua
-- Phase 1 FoodType registry for CookingTime / SoulFilcher items
-- Data-only. No logic.

local FoodType = require "core/domain/FoodType"

local FoodTypes = {

    -- -----------------------------------------------------------------------
    -- PrepMap targets (items that can become pieces)
    -- -----------------------------------------------------------------------

    FoodType.new({ fullType = "filcher.Calabrese",      prepTo = "KitchenConsolidation.MeatPieces" }),
    FoodType.new({ fullType = "filcher.CannedHamOpen", prepTo = "KitchenConsolidation.MeatPieces" }),
    FoodType.new({ fullType = "filcher.SFPorkribs",    prepTo = "KitchenConsolidation.MeatPieces" }),
    FoodType.new({ fullType = "filcher.SFSausage",     prepTo = "KitchenConsolidation.MeatPieces" }),
    FoodType.new({ fullType = "filcher.Smallbirdmeat", prepTo = "KitchenConsolidation.MeatPieces" }),
    FoodType.new({ fullType = "filcher.SmokedMeat",    prepTo = "KitchenConsolidation.MeatPieces" }),

    -- -----------------------------------------------------------------------
    -- Containerized foods (byproduct preserved)
    -- -----------------------------------------------------------------------

    FoodType.new({
        fullType = "filcher.CannedHamOpen",
        isContainerized = true,
        byproductsOnEmpty = { "Base.TinCanEmpty" },
    }),

    FoodType.new({
        fullType = "filcher.CannedSoupOpen",
        isContainerized = true,
        byproductsOnEmpty = { "Base.TinCanEmpty" },
    }),

    FoodType.new({
        fullType = "filcher.OpenCannedSpagetti",
        isContainerized = true,
        byproductsOnEmpty = { "Base.TinCanEmpty" },
    }),

    FoodType.new({
        fullType = "filcher.OpenCannedSpinach",
        isContainerized = true,
        byproductsOnEmpty = { "Base.TinCanEmpty" },
    }),

    FoodType.new({
        fullType = "filcher.SFCatfoodOpen",
        isContainerized = true,
        byproductsOnEmpty = { "Base.TinCanEmpty" },
    }),

    FoodType.new({
        fullType = "filcher.SFChocolateWaferSticksJarOpen",
        isContainerized = true,
        byproductsOnEmpty = { "filcher.JarAndLid" },
    }),

    FoodType.new({
        fullType = "filcher.SFPickles",
        isContainerized = true,
        byproductsOnEmpty = { "filcher.JarAndLid" },
    }),

    FoodType.new({
        fullType = "filcher.SFJelly",
        isContainerized = true,
        byproductsOnEmpty = { "filcher.JarAndLid" },
    }),

    FoodType.new({
        fullType = "filcher.SFTomatoSauce",
        isContainerized = true,
        byproductsOnEmpty = { "filcher.JarAndLid" },
    }),

    -- -----------------------------------------------------------------------
    -- Fungible bulk foods (no byproduct)
    -- -----------------------------------------------------------------------

    FoodType.new({ fullType = "filcher.Macaroni",         isContainerized = true }),
    FoodType.new({ fullType = "filcher.SFPotatoSliced",  isContainerized = true }),
    FoodType.new({ fullType = "filcher.SFBeans",         isContainerized = true }),
    FoodType.new({ fullType = "filcher.BreadPieces",     isContainerized = true }),
    FoodType.new({ fullType = "filcher.SFHazelnutCream", isContainerized = true }),

    FoodType.new({ fullType = "filcher.Cinnamon",  isContainerized = true }),
    FoodType.new({ fullType = "filcher.SFPaprika", isContainerized = true }),
    FoodType.new({ fullType = "filcher.SFCurry",   isContainerized = true }),
}

return FoodTypes
