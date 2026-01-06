local Capability = require("core/domain/Capability")
local Resource   = require("core/domain/Resource")

local Provider   = require("core/traits/Provider")
local Storage    = require("core/traits/Storage")

local Capabilities = Capability.Capabilities

print("provider_trait_test")

-- Minimal fake entity
local function newEntity()
    return {
        capabilities = Capabilities.new()
    }
end

----------------------------------------------------------------
-- Test: Provider registers capability
----------------------------------------------------------------

do
    local e = newEntity()

    Storage.water(e, { capacity = 40, current = 15 })
    Provider.water(e, { priority = 2 })

    local provider = e.capabilities:getProvider(Resource.WATER)
    assert(provider ~= nil, "Provider capability not registered")
    assert(provider.resource == Resource.WATER)
    assert(provider.priority == 2)
end

----------------------------------------------------------------
-- Test: getAvailable reads from store
----------------------------------------------------------------

do
    local e = newEntity()

    Storage.water(e, { capacity = 25, current = 9 })
    Provider.water(e, {})

    local avail = e:getAvailable(Resource.WATER)
    assert(avail == 9, "getAvailable did not read from store")
end

----------------------------------------------------------------
-- Test: drain mutates store
----------------------------------------------------------------

do
    local e = newEntity()

    Storage.water(e, { capacity = 30, current = 12 })
    Provider.water(e, {})

    local ok = e:drain(Resource.WATER, 5)
    assert(ok, "Provider drain failed")

    local remaining = e.capabilities:getStore(Resource.WATER).current
    assert(remaining == 7, "Provider drain did not mutate store")
end

----------------------------------------------------------------
-- Test: disabled provider ignored
----------------------------------------------------------------

do
    local e = newEntity()

    Storage.water(e, { capacity = 20, current = 10 })
    Provider.water(e, { enabled = false })

    local provider = e.capabilities:getProvider(Resource.WATER)
    assert(provider ~= nil, "Provider capability missing")

    local avail = e:getAvailable(Resource.WATER)
    assert(avail == 0, "Disabled provider should not expose availability")

    local ok, reason = e:drain(Resource.WATER, 3)
    assert(not ok, "Drain succeeded despite disabled provider")
end

print("provider_trait_test OK")
