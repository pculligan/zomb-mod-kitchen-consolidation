local Resource = require("core/domain/Resource")

print("core/domain/Resource_test")

-- Collect expected resources
local expected = {
    Resource.WATER,
    Resource.PUMPABLE_WATER,
    Resource.FUEL,
    Resource.PROPANE,
    Resource.ELECTRICITY,
}

-- Test: all expected resources exist
for _, r in ipairs(expected) do
    assert(r ~= nil, "Expected resource is nil")
end

-- Test: Resource.isValid works for expected resources
for _, r in ipairs(expected) do
    assert(Resource.isValid(r), "core/domain/Resource.isValid failed for " .. tostring(r))
end

-- Test: Resource.isValid rejects unknown values
assert(not Resource.isValid("invalid_resource"), "core/domain/Resource.isValid accepted invalid resource")

-- Test: no duplicate resource values
local seen = {}
for _, r in ipairs(expected) do
    assert(not seen[r], "Duplicate resource value detected: " .. tostring(r))
    seen[r] = true
end

print("core/domain/Resource_test OK")
