-- KitchenConsolidation_Items_SoulFilcher.lua
-- Phase 1 compatibility data for SoulFilcher (CookingTime)
-- Data-only module. No logic.
-- Items included here explicitly conform to Combine Food Phase-1 rules.

local Items = {}

-- ---------------------------------------------------------------------------
-- Containerized Foods (Byproduct Preserved)
-- ---------------------------------------------------------------------------

Items.WHITELIST = {
    -- Opened canned foods (tin can byproduct)
    ["filcher.CannedHamOpen"] = true,
    ["filcher.CannedSoupOpen"] = true,
    ["filcher.OpenCannedSpagetti"] = true,
    ["filcher.OpenCannedSpinach"] = true,
    ["filcher.SFCatfoodOpen"] = true,

    -- Opened jarred foods (jar + lid byproduct)
    ["filcher.SFChocolateWaferSticksJarOpen"] = true,
    ["filcher.SFPickles"] = true,
    ["filcher.SFJelly"] = true,
    ["filcher.SFTomatoSauce"] = true,
}

Items.BYPRODUCT_ON_EMPTY = {
    -- Tin cans
    ["filcher.CannedSoupOpen"] = "Base.TinCanEmpty",
    ["filcher.OpenCannedSpagetti"] = "Base.TinCanEmpty",
    ["filcher.OpenCannedSpinach"] = "Base.TinCanEmpty",
    ["filcher.SFCatfoodOpen"] = "Base.TinCanEmpty",

    -- Jars
    ["filcher.SFChocolateWaferSticksJarOpen"] = "filcher.JarAndLid",
    ["filcher.SFPickles"] = "filcher.JarAndLid",
    ["filcher.SFJelly"] = "filcher.JarAndLid",
    ["filcher.SFTomatoSauce"] = "filcher.JarAndLid",
}

-- ---------------------------------------------------------------------------
-- Fungible Bulk Foods (No Byproduct)
-- ---------------------------------------------------------------------------

Items.FUNGIBLE_BULK = {
    ["filcher.Macaroni"] = true,
    ["filcher.SFPotatoSliced"] = true,
    ["filcher.SFBeans"] = true,
    ["filcher.BreadPieces"] = true,
    ["filcher.SFHazelnutCream"] = true,

    -- Processed seasonings
    ["filcher.Cinnamon"] = true,
    ["filcher.SFPaprika"] = true,
    ["filcher.SFCurry"] = true,
}

return Items