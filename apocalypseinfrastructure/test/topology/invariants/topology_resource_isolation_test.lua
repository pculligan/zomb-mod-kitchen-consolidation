local Pipe     = require("topology/entities/Pipe")
local Valve    = require("topology/entities/Valve")
local Registry = require("topology/net/Registry")
local Resource = require("core/domain/Resource")

print("topology_resource_isolation_test")

local function observed()
    return {}
end

local function pos(x,y,z)
    return { x=x, y=y, z=z or 0 }
end

----------------------------------------------------------------
-- Pipes of different resources do not connect when adjacent
----------------------------------------------------------------

do
    Registry.reset()

    local water = Pipe.WaterPipe.apply{
        id = "w",
        object = observed(),
        position = pos(0,0,0),
        attachedFaces = { floor = true },
    }

    local fuel = Pipe.FuelPipe.apply{
        id = "f",
        object = observed(),
        position = pos(1,0,0), -- adjacent tile
        attachedFaces = { floor = true },
    }

    water:attach()
    fuel:attach()

    assert(water.node.neighbors["f"] == nil)
    assert(fuel.node.neighbors["w"] == nil)

    assert(water.node.network ~= fuel.node.network)
end

----------------------------------------------------------------
-- Valve only gates its own topologyResource
----------------------------------------------------------------

-- Valve gating is scoped to its topologyResource and surface intent.
-- Other resources and surfaces remain unaffected.

do
    Registry.reset()

    -- water line: a -- v -- b
    local a = Pipe.WaterPipe.apply{
        id = "a",
        object = observed(),
        position = pos(2,2,0),
        attachedFaces = { floor = true },
    }

    local v = Valve.WaterValve.apply{
        id = "v",
        object = observed(),
        position = pos(3,2,0),
        attachedFaces = { floor = true },
        open = false,
    }

    local b = Pipe.WaterPipe.apply{
        id = "b",
        object = observed(),
        position = pos(4,2,0),
        attachedFaces = { floor = true },
    }

    -- adjacent fuel pipe near the valve position on the floor
    local fuel = Pipe.FuelPipe.apply{
        id = "f",
        object = observed(),
        position = pos(3,3,0),
        attachedFaces = { floor = true },
    }

    a:attach()
    v:attach()
    b:attach()
    fuel:attach()

    -- water adjacency is gated
    assert(a.node.neighbors["b"] == nil)

    -- fuel topology unaffected
    assert(fuel.node.network ~= nil)

    -- opening valve restores water adjacency only
    v:setOpen(true)

    assert(a.node.neighbors["v"] ~= nil)
    assert(v.node.neighbors["b"] ~= nil)
    assert(a.node.network == b.node.network)

    -- fuel still isolated from water
    assert(fuel.node.neighbors["a"] == nil)
    assert(fuel.node.neighbors["v"] == nil)
    assert(fuel.node.neighbors["b"] == nil)
end

----------------------------------------------------------------
-- Valve does not gate other resources on the same surface
-- (fuel can occupy the same cell because resource differs)
----------------------------------------------------------------

do
    Registry.reset()

    -- water valve at center cell
    local vw = Valve.WaterValve.apply{
        id = "vw",
        object = observed(),
        position = pos(11,0,0),
        attachedFaces = { floor = true },
        open = false,
    }

    -- fuel line: x -- mid -- y
    local x = Pipe.FuelPipe.apply{
        id = "x",
        object = observed(),
        position = pos(10,0,0),
        attachedFaces = { floor = true },
    }

    local mid = Pipe.FuelPipe.apply{
        id = "mid",
        object = observed(),
        position = pos(11,0,0), -- same cell as water valve, different resource
        attachedFaces = { floor = true },
    }

    local y = Pipe.FuelPipe.apply{
        id = "y",
        object = observed(),
        position = pos(12,0,0),
        attachedFaces = { floor = true },
    }

    x:attach()
    vw:attach()
    mid:attach()
    y:attach()

    -- fuel adjacency is unaffected by a water valve
    assert(x.node.neighbors["mid"] ~= nil)
    assert(mid.node.neighbors["y"] ~= nil)
    assert(x.node.network == y.node.network)
end

----------------------------------------------------------------
-- Same cell, different surfaces, different resources remain isolated
----------------------------------------------------------------

do
    Registry.reset()

    local water = Pipe.WaterPipe.apply{
        id = "wcell",
        object = observed(),
        position = pos(20,20,0),
        attachedFaces = { floor = true },
    }

    local fuel = Pipe.FuelPipe.apply{
        id = "fcell",
        object = observed(),
        position = pos(20,20,0),
        attachedFaces = { north = true },
    }

    water:attach()
    fuel:attach()

    assert(water.node.neighbors["fcell"] == nil)
    assert(fuel.node.neighbors["wcell"] == nil)
    assert(water.node.network ~= fuel.node.network)
end

----------------------------------------------------------------
-- Vertical adjacency does not cross resources
----------------------------------------------------------------

do
    Registry.reset()

    local water = Pipe.WaterPipe.apply{
        id = "wv0",
        object = observed(),
        position = pos(30,30,0),
        attachedFaces = { north = true },
    }

    local fuel = Pipe.FuelPipe.apply{
        id = "fv1",
        object = observed(),
        position = pos(30,30,1),
        attachedFaces = { north = true },
    }

    water:attach()
    fuel:attach()

    assert(water.node.neighbors["fv1"] == nil)
    assert(fuel.node.neighbors["wv0"] == nil)
    assert(water.node.network ~= fuel.node.network)
end

----------------------------------------------------------------
-- Valve bypass via alternate path does not affect other resource
----------------------------------------------------------------

do
    Registry.reset()

    -- water: a -- v -- b
    local a = Pipe.WaterPipe.apply{
        id = "wa",
        object = observed(),
        position = pos(40,40,0),
        attachedFaces = { floor = true },
    }

    local v = Valve.WaterValve.apply{
        id = "wv",
        object = observed(),
        position = pos(41,40,0),
        attachedFaces = { floor = true },
        open = false,
    }

    local b = Pipe.WaterPipe.apply{
        id = "wb",
        object = observed(),
        position = pos(42,40,0),
        attachedFaces = { floor = true },
    }

    -- fuel bypass path
    local f1 = Pipe.FuelPipe.apply{
        id = "fa",
        object = observed(),
        position = pos(41,41,0),
        attachedFaces = { floor = true },
    }

    local f2 = Pipe.FuelPipe.apply{
        id = "fb",
        object = observed(),
        position = pos(42,41,0),
        attachedFaces = { floor = true },
    }

    a:attach()
    v:attach()
    b:attach()
    f1:attach()
    f2:attach()

    -- water still gated
    assert(a.node.neighbors["b"] == nil)

    -- fuel network intact
    assert(f1.node.network == f2.node.network)
end

print("topology_resource_isolation_test OK")
