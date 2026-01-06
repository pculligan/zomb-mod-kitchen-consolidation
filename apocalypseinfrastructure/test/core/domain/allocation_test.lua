

-- allocation_test.lua
--
-- Pure Allocation strategy tests.
-- These tests validate ONLY allocation math and plan construction.
-- No topology, no entities, no storage mutation.

local Allocation = require("core/domain/Allocation")

print("allocation_test")

-- helper to extract provider amounts by id
local function amounts(plan)
    local out = {}
    for _, e in ipairs(plan) do
        out[e.provider] = (out[e.provider] or 0) + e.amount
    end
    return out
end

----------------------------------------------------------------
-- SEQUENTIAL
----------------------------------------------------------------
do
    local providers = {
        { provider = "p1", available = 10 },
        { provider = "p2", available = 10 },
    }

    local plan, applied = Allocation.sequential(providers, 10)
    local a = amounts(plan)

    assert(applied == 10)
    assert(a.p1 == 10)
    assert(a.p2 == nil)
end

----------------------------------------------------------------
-- PROPORTIONAL BY QUANTITY (true weighted)
----------------------------------------------------------------
do
    local providers = {
        { provider = "p1", available = 10 },
        { provider = "p2", available = 10 },
    }

    local plan, applied = Allocation.proportional_quantity(providers, 10)
    local a = amounts(plan)

    assert(applied == 10)
    assert(a.p1 == 5)
    assert(a.p2 == 5)
end

do
    local providers = {
        { provider = "p1", available = 10 },
        { provider = "p2", available = 2 },
    }

    local plan, applied = Allocation.proportional_quantity(providers, 6)
    local a = amounts(plan)

    assert(applied == 6)
    assert(a.p1 == 5)
    assert(a.p2 == 1)
end

----------------------------------------------------------------
-- PROPORTIONAL BY DISTANCE
----------------------------------------------------------------
do
    local providers = {
        { provider = "near", available = 10 },
        { provider = "far",  available = 10 },
    }

    local plan, applied = Allocation.proportional_distance(
        providers,
        6,
        { distances = { near = 1, far = 3 } }
    )

    local a = amounts(plan)

    assert(applied == 6)
    assert(a.near > a.far)
    assert(a.near + a.far == 6)
end

----------------------------------------------------------------
-- LEVELING
----------------------------------------------------------------
do
    local providers = {
        { provider = "big",   available = 10 },
        { provider = "small", available = 2 },
    }

    local plan, applied = Allocation.leveling(providers, 6)
    local a = amounts(plan)

    assert(applied == 6)
    -- leveling drains the fullest provider first
    assert(a.big == 6)
    assert(a.small == nil or a.small == 0)
end

print("allocation_test OK")