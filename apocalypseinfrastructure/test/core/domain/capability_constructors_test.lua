local Capability = require("core/domain/Capability")
local Resource   = require("core/domain/Resource")

local Capabilities                = Capability.Capabilities
local ProviderCapability           = Capability.ProviderCapability
local ConsumerCapability           = Capability.ConsumerCapability
local StoreCapability              = Capability.StoreCapability

print("capability_constructors_test")

-- Helper: assert metatable
local function assertType(obj, expected)
    assert(getmetatable(obj) == expected,
        "Expected capability type " .. tostring(expected) .. ", got " .. tostring(getmetatable(obj)))
end

----------------------------------------------------------------
-- Provider capability constructors
----------------------------------------------------------------

local wp = Capability.WaterProviderCapability{ priority = 2, meta = { quality = "tainted" } }
assertType(wp, ProviderCapability)
assert(wp.resource == Resource.WATER)
assert(wp.priority == 2)
assert(wp.meta.quality == "tainted")

local fp = Capability.FuelProviderCapability{ meta = { octane = 91 } }
assertType(fp, ProviderCapability)
assert(fp.resource == Resource.FUEL)
assert(fp.meta.octane == 91)

local pp = Capability.PropaneProviderCapability{}
assertType(pp, ProviderCapability)
assert(pp.resource == Resource.PROPANE)

local ep = Capability.ElectricityProviderCapability{ meta = { voltage = 240 } }
assertType(ep, ProviderCapability)
assert(ep.resource == Resource.ELECTRICITY)
assert(ep.meta.voltage == 240)

local pwp = Capability.PumpableWaterProviderCapability{ meta = { depth = 10 } }
assertType(pwp, ProviderCapability)
assert(pwp.resource == Resource.PUMPABLE_WATER)
assert(pwp.meta.depth == 10)

----------------------------------------------------------------
-- Consumer capability constructors
----------------------------------------------------------------

local wc = Capability.WaterConsumerCapability{ meta = { filtration = "filter" } }
assertType(wc, ConsumerCapability)
assert(wc.resource == Resource.WATER)
assert(wc.meta.filtration == "filter")

local fc = Capability.FuelConsumerCapability{ meta = { efficiency = 0.8 } }
assertType(fc, ConsumerCapability)
assert(fc.resource == Resource.FUEL)
assert(fc.meta.efficiency == 0.8)

local pc = Capability.PropaneConsumerCapability{ meta = { burnRate = 5 } }
assertType(pc, ConsumerCapability)
assert(pc.resource == Resource.PROPANE)
assert(pc.meta.burnRate == 5)

local ec = Capability.ElectricityConsumerCapability{ meta = { watts = 500 } }
assertType(ec, ConsumerCapability)
assert(ec.resource == Resource.ELECTRICITY)
assert(ec.meta.watts == 500)

----------------------------------------------------------------
-- Store capability constructors
----------------------------------------------------------------

local ws = Capability.WaterStoreCapability{ capacity = 50, current = 10 }
assertType(ws, StoreCapability)
assert(ws.resource == Resource.WATER)
assert(ws.capacity == 50)
assert(ws.current == 10)

local fs = Capability.FuelStoreCapability{ capacity = 20, current = 5 }
assertType(fs, StoreCapability)
assert(fs.resource == Resource.FUEL)
assert(fs.capacity == 20)
assert(fs.current == 5)

local ps = Capability.PropaneStoreCapability{ capacity = 30, current = 15 }
assertType(ps, StoreCapability)
assert(ps.resource == Resource.PROPANE)

local es = Capability.ElectricityStoreCapability{ capacity = 100, current = 40 }
assertType(es, StoreCapability)
assert(es.resource == Resource.ELECTRICITY)

local pws = Capability.PumpableWaterStoreCapability{ capacity = 200, current = 60 }
assertType(pws, StoreCapability)
assert(pws.resource == Resource.PUMPABLE_WATER)
assert(pws.current == 60)

----------------------------------------------------------------
-- Capability container placement
----------------------------------------------------------------

local caps = Capabilities.new()

caps:addProvider(wp)
caps:addConsumer(wc)
caps:addStore(ws)

assert(caps:getProvider(Resource.WATER) == wp)
assert(caps:getConsumer(Resource.WATER) == wc)
assert(caps:getStore(Resource.WATER) == ws)

print("capability_constructors_test OK")
