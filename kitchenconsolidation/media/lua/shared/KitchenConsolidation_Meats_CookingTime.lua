

local Meats = {}

Meats.SOURCES = {
    -- Start small; expand after validation
    ["filcher.Calabrese"] = true,
    ["filcher.CannedHamOpen"] = true,
    ["filcher.SFPorkribs"] = true,
    ["filcher.SFSausage"] = true,
    ["filcher.Smallbirdmeat"] = true,
    ["filcher.SmokedMeat"] = true,
}

Meats.BYPRODUCT_ON_EMPTY = {
    -- Tin cans
    ["filcher.CannedHamOpen"] = "Base.TinCanEmpty",
}

return Meats