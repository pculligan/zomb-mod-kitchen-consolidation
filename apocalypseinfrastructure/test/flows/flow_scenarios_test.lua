-- flow_scenarios_test.lua
--
-- Integration tests for Consumer → Provider → Storage flow.
-- Allocation math is NOT asserted here.
-- Allocation correctness is tested exclusively in allocation_test.lua.

local Registry   = require("topology/net/Registry")
local Entity     = require("topology/entities/Entity")

local Storage    = require("core/traits/Storage")
local Provider   = require("core/traits/Provider")
local Consumer   = require("core/traits/Consumer")

local Resource   = require("core/domain/Resource")

print("flow_scenarios_test")

local function pos(x,y,z) return { x=x, y=y, z=z or 0 } end
local function observed() return {} end

local providerIndex = 0
local function nextProviderPos()
    providerIndex = providerIndex + 1
    return pos(providerIndex, 0, 0)
end

local function makeProvider(id, amount)
    local e = Entity.new{
        id = id,
        topologyResource = Resource.WATER,
        position = nextProviderPos(),
        observed = observed(),
    }
    Storage.water(e, { capacity = amount, current = amount })
    Provider.water(e)
    e:attach()
    return e
end

local function makeConsumer(id)
    local e = Entity.new{
        id = id,
        topologyResource = Resource.WATER,
        position = pos(0,0,0), -- adjacent to provider at (1,0,0)
        observed = observed(),
    }
    Consumer.water(e)
    e:attach()
    return e
end

-- Scenario 1
do
    Registry.reset()
    providerIndex = 0

    local p = makeProvider("p1", 10)
    local c = makeConsumer("c1")

    local plan = c:request(5)
    local result = c:applyPlan(plan)

    assert(result.applied == 5)
    assert(p.capabilities:getStore(Resource.WATER).current == 5)
end

-- Scenario 2
do
    Registry.reset()
    providerIndex = 0

    local p = makeProvider("p1", 3)
    local c = makeConsumer("c1")

    local plan = c:request(5)
    local result = c:applyPlan(plan)

    assert(result.applied == 3)
    assert(p.capabilities:getStore(Resource.WATER).current == 0)
end

-- Scenario 3
do
    Registry.reset()
    providerIndex = 0

    local p1 = makeProvider("p1", 10)
    local p2 = makeProvider("p2", 5)
    local c  = makeConsumer("c1")

    -- Disable provider via capability
    local cap = p1.capabilities:getProvider(Resource.WATER)
    assert(cap ~= nil)
    cap.enabled = false

    local plan = c:request(4)
    local result = c:applyPlan(plan)

    assert(result.applied == 4)
    assert(p1.capabilities:getStore(Resource.WATER).current == 10)
    assert(p2.capabilities:getStore(Resource.WATER).current == 1)
end

print("flow_scenarios_test OK")