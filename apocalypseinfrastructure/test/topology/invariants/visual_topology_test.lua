local assert = require("assert")

local Registry = require("topology/net/Registry")
local BaseConnector = require("flow/BaseConnector")
local WaterPipeConnector = require("flow/Water/WaterPipeConnector")

-- Simple phase helper
local function phase(name, fn)
    print("\n=== PHASE: " .. name .. " ===")
    Registry.reset()
    fn()
    print("=== PASS: " .. name .. " ===\n")
end

-- Fake world object anchor
local function fakeObj(id)
    return { __id = id }
end

-- Helper to create a water pipe at a position
local function waterPipe(id, x, y, z)
    return WaterPipeConnector.new({
        id = id,
        object = fakeObj(id),
        position = { x = x, y = y, z = z or 0 },
    })
end

----------------------------------------------------------------
-- Visual mask basics
----------------------------------------------------------------

phase("isolated_pipe_has_zero_mask", function()
    local p = waterPipe("p", 0, 0, 0)
    p:attach()

    assert.eq(p.visualMask, 0, "isolated pipe should have no connections")
end)

phase("north_neighbor_sets_north_bit", function()
    local p1 = waterPipe("p1", 0, 0, 0)
    local p2 = waterPipe("p2", 0, -1, 0)

    p1:attach()
    p2:attach()

    assert.eq(p1.visualMask, 1, "north neighbor should set N bit")
    assert.eq(p2.visualMask, 4, "south neighbor should set S bit")
end)

phase("east_west_connection", function()
    local p1 = waterPipe("p1", 0, 0, 0)
    local p2 = waterPipe("p2", 1, 0, 0)

    p1:attach()
    p2:attach()

    assert.eq(p1.visualMask, 2, "east neighbor should set E bit")
    assert.eq(p2.visualMask, 8, "west neighbor should set W bit")
end)

phase("straight_vertical_pipe_mask", function()
    local p1 = waterPipe("p1", 0, 0, 0)
    local p2 = waterPipe("p2", 0, -1, 0)
    local p3 = waterPipe("p3", 0, 1, 0)

    p1:attach()
    p2:attach()
    p3:attach()

    assert.eq(p1.visualMask, 5, "north+south should be straight vertical (5)")
end)

phase("corner_pipe_mask", function()
    local p1 = waterPipe("p1", 0, 0, 0)
    local p2 = waterPipe("p2", 1, 0, 0)
    local p3 = waterPipe("p3", 0, -1, 0)

    p1:attach()
    p2:attach()
    p3:attach()

    assert.eq(p1.visualMask, 3, "north+east corner should be mask 3")
end)

phase("cross_pipe_mask", function()
    local p = waterPipe("p", 0, 0, 0)

    local n = waterPipe("n", 0, -1, 0)
    local e = waterPipe("e", 1, 0, 0)
    local s = waterPipe("s", 0, 1, 0)
    local w = waterPipe("w", -1, 0, 0)

    p:attach()
    n:attach()
    e:attach()
    s:attach()
    w:attach()

    assert.eq(p.visualMask, 15, "cross should have all bits set (15)")
end)

----------------------------------------------------------------
-- Local recomputation behavior
----------------------------------------------------------------

phase("detach_recomputes_neighbors", function()
    local p1 = waterPipe("p1", 0, 0, 0)
    local p2 = waterPipe("p2", 1, 0, 0)

    p1:attach()
    p2:attach()

    assert.eq(p1.visualMask, 2)
    assert.eq(p2.visualMask, 8)

    p2:onDetach()

    assert.eq(p1.visualMask, 0, "neighbor mask should update after detach")
end)

----------------------------------------------------------------
-- Resource scoping
----------------------------------------------------------------

phase("different_resources_do_not_visually_connect", function()
    local water = waterPipe("water", 0, 0, 0)

    -- If FuelPipeConnector exists, test explicitly.
    -- Otherwise simulate a fake connector with different resource.
    local fakeFuel = BaseConnector.new({
        id = "fuel",
        observed = fakeObj("fuel"),
        position = { x = 1, y = 0, z = 0 },
        resource = "fuel",
        capabilities = {}
    })

    water:attach()
    fakeFuel:attach()

    assert.eq(water.visualMask, 0, "different resource should not connect visually")
end)

----------------------------------------------------------------
-- Z-axis isolation
----------------------------------------------------------------

phase("same_xy_different_z_do_not_connect", function()
    local p1 = waterPipe("p1", 0, 0, 0)
    local p2 = waterPipe("p2", 0, 0, 1)

    p1:attach()
    p2:attach()

    assert.eq(p1.visualMask, 0, "different Z should not connect")
    assert.eq(p2.visualMask, 0, "different Z should not connect")
end)