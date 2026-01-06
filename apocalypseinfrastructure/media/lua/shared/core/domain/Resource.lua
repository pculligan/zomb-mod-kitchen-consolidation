

-- Resource.lua
-- Canonical resource identifiers for the system.
-- These are interned strings (Lua-idiomatic “enum”).
-- Do NOT compare resources using raw string literals elsewhere.

local Resource = {}

----------------------------------------------------------------
-- Fluid resources
----------------------------------------------------------------

Resource.WATER            = "water"             -- potable / non-pump water
Resource.PUMPABLE_WATER   = "pumpable_water"    -- wells, rivers, intakes
Resource.FUEL             = "fuel"
Resource.PROPANE          = "propane"
Resource.ELECTRICITY      = "electricity"

----------------------------------------------------------------
-- Utility helpers (optional but useful)
----------------------------------------------------------------

-- Validate a resource identifier
function Resource.isValid(value)
    for _, v in pairs(Resource) do
        if v == value then
            return true
        end
    end
    return false
end

-- Human-readable name (for UI / logs)
function Resource.displayName(value)
    if value == Resource.WATER then return "Water" end
    if value == Resource.PUMPABLE_WATER then return "Pumpable Water" end
    if value == Resource.FUEL then return "Fuel" end
    if value == Resource.PROPANE then return "Propane" end
    if value == Resource.ELECTRICITY then return "Electricity" end
    return tostring(value)
end

return Resource