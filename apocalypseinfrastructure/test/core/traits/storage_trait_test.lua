local Capability = require("core/domain/Capability")
local Resource   = require("core/domain/Resource")
local Storage    = require("core/traits/Storage")

local Capabilities = Capability.Capabilities

print("storage_trait_test")

-- Minimal fake entity
local function newEntity()
    return {
        capabilities = Capabilities.new()
    }
end

----------------------------------------------------------------
-- Test: Store adds capability
----------------------------------------------------------------

do
    local e = newEntity()

    Storage.water(e, { capacity = 50, current = 20 })

    local store = e.capabilities:getStore(Resource.WATER)
    assert(store ~= nil, "Store capability not added")
    assert(store.capacity == 50)
    assert(store.current == 20)
end

----------------------------------------------------------------
-- Test: Drain mutates store.current
----------------------------------------------------------------

do
    local e = newEntity()

    Storage.water(e, { capacity = 30, current = 10 })

    local ok = e:drain(Resource.WATER, 4)
    assert(ok, "Drain failed")
    assert(e.capabilities:getStore(Resource.WATER).current == 6,
        "Drain did not reduce store.current")
end

----------------------------------------------------------------
-- Test: Capacity respected (over-drain clamps)
----------------------------------------------------------------

do
    local e = newEntity()

    Storage.water(e, { capacity = 15, current = 5 })

    local ok = e:drain(Resource.WATER, 20)
    assert(ok, "Drain failed")
    assert(e.capabilities:getStore(Resource.WATER).current == 0,
        "Over-drain did not clamp to zero")
end

----------------------------------------------------------------
-- Test: Observed getter/setter syncs
----------------------------------------------------------------

do
    local observed = {
        value = 12,
        getWaterAmount = function(self) return self.value end,
        setWaterAmount = function(self, v) self.value = v end,
    }

    local e = newEntity()

    Storage.water(e, {
        capacity = 20,
        current  = 12,
        observed = observed,
    })

    -- Pull from observed
    local avail = e:getAvailable(Resource.WATER)
    assert(avail == 12, "Observed getter not used")

    -- Drain and push to observed
    e:drain(Resource.WATER, 7)
    assert(observed.value == 5, "Observed setter not updated")
end

print("storage_trait_test OK")
