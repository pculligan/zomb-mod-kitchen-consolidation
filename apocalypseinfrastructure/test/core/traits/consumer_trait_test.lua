local Capability = require("core/domain/Capability")
local Resource   = require("core/domain/Resource")

local Provider   = require("core/traits/Provider")
local Consumer   = require("core/traits/Consumer")
local Storage    = require("core/traits/Storage")

local Allocation = require("core/domain/Allocation")

local Capabilities = Capability.Capabilities

print("consumer_trait_test")

-- Minimal fake entity
local function newEntity()
    return {
        capabilities = Capabilities.new()
    }
end

----------------------------------------------------------------
-- Test: Request generates plan
----------------------------------------------------------------

do
    local provider = newEntity()
    Storage.water(provider, { capacity = 20, current = 10 })
    Provider.water(provider, {})

    local consumer = newEntity()
    Consumer.water(consumer, {})

    -- Fake network wiring
    consumer.node = { network = { nodes = {
        { entity = provider },
        { entity = consumer },
    } } }

    local result = consumer:request(5)
    assert(result.plan ~= nil, "No plan generated")
    assert(result.fulfilled == 5, "Request not fully fulfilled")
end

----------------------------------------------------------------
-- Test: Plan application drains correctly
----------------------------------------------------------------

do
    local provider = newEntity()
    Storage.water(provider, { capacity = 30, current = 12 })
    Provider.water(provider, {})

    local consumer = newEntity()
    Consumer.water(consumer, {})

    consumer.node = { network = { nodes = {
        { entity = provider },
        { entity = consumer },
    } } }

    local result = consumer:request(7)
    local applied = consumer:applyPlan(result)

    local remaining = provider.capabilities:getStore(Resource.WATER).current
    assert(remaining == 5, "Drain did not reduce provider store correctly")
end

----------------------------------------------------------------
-- Test: Partial fulfillment works
----------------------------------------------------------------

do
    local provider = newEntity()
    Storage.water(provider, { capacity = 10, current = 4 })
    Provider.water(provider, {})

    local consumer = newEntity()
    Consumer.water(consumer, {})

    consumer.node = { network = { nodes = {
        { entity = provider },
        { entity = consumer },
    } } }

    local result = consumer:request(6)
    assert(result.fulfilled == 4, "Partial fulfillment amount incorrect")

    consumer:applyPlan(result)
    local remaining = provider.capabilities:getStore(Resource.WATER).current
    assert(remaining == 0, "Provider store not fully drained on partial fulfillment")
end

----------------------------------------------------------------
-- Test: Fallback works (one provider fails)
----------------------------------------------------------------

do
    local provider1 = newEntity()
    Storage.water(provider1, { capacity = 10, current = 5 })
    Provider.water(provider1, {})

    local provider2 = newEntity()
    Storage.water(provider2, { capacity = 10, current = 5 })
    Provider.water(provider2, {})

    -- Sabotage provider1 drain
    provider1.drain = function()
        return false, "simulated_failure"
    end

    local consumer = newEntity()
    Consumer.water(consumer, {})

    consumer.node = { network = { nodes = {
        { entity = provider1 },
        { entity = provider2 },
        { entity = consumer },
    } } }

    local result = consumer:request(5)
    consumer:applyPlan(result)

    local remaining1 = provider1.capabilities:getStore(Resource.WATER).current
    local remaining2 = provider2.capabilities:getStore(Resource.WATER).current

    assert(remaining1 == 5, "Failing provider should not be drained")
    assert(remaining2 == 0, "Fallback provider should be drained")
end

print("consumer_trait_test OK")
