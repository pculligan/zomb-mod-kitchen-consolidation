local Capability = require("core/domain/Capability")
local Resource   = require("core/domain/Resource")

local Provider   = require("core/traits/Provider")
local Consumer   = require("core/traits/Consumer")
local Storage    = require("core/traits/Storage")

local Capabilities = Capability.Capabilities

print("capability_ordering_test")

-- Minimal fake entity (no Registry, no Node)
local function newEntity()
    return { capabilities = Capabilities.new() }
end

----------------------------------------------------------------
-- Test: Provider before Storage throws
----------------------------------------------------------------

do
    local e = newEntity()
    local ok, err = pcall(function()
        Provider.water(e, { priority = 1 })
    end)
    assert(not ok, "Provider before Storage did not throw")
end

----------------------------------------------------------------
-- Test: Correct order succeeds
----------------------------------------------------------------

do
    local e = newEntity()

    -- Storage -> Provider -> Consumer
    Storage.water(e, { capacity = 10, current = 5 })
    Provider.water(e, { priority = 1 })
    Consumer.water(e, {})

    -- Structural sanity checks
    assert(e.capabilities:hasStore(Resource.WATER))
    assert(e.capabilities:hasProvider(Resource.WATER))
    assert(e.capabilities:getConsumer(Resource.WATER) ~= nil)
end

print("capability_ordering_test OK")
