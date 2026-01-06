local Pipe     = require("topology/entities/Pipe")
local Entity   = require("topology/entities/Entity")
local Registry = require("topology/net/Registry")
local Resource = require("core/domain/Resource")

print("pipe_entity_test")

local function observed()
    return {}
end

local function pos(x,y,z)
    return { x=x, y=y, z=z or 0 }
end

----------------------------------------------------------------
-- Construction
----------------------------------------------------------------

do
    local p = Pipe.WaterPipe.apply{
        id = "p1",
        object = observed(),
        position = pos(1,1,0),
    }

    assert(p.topologyResource == Resource.WATER)
    assert(p.node ~= nil)
end

----------------------------------------------------------------
-- Surface occupancy rules
----------------------------------------------------------------

do
    Registry.reset()

    local floorPipe = Pipe.WaterPipe.apply{
        id = "p1",
        object = observed(),
        position = pos(2,2,0),
        attachedFaces = { floor = true },
    }
    floorPipe:attach()

    -- Same surface + resource is not allowed
    local floorPipe2 = Pipe.WaterPipe.apply{
        id = "p2",
        object = observed(),
        position = pos(2,2,0),
        attachedFaces = { floor = true },
    }

    local ok, err = pcall(function() floorPipe2:attach() end)
    assert(ok == false)
end

do
    Registry.reset()

    -- One pipe entity may attach to multiple surfaces in the same cell
    local waterPipe = Pipe.WaterPipe.apply{
        id = "w",
        object = observed(),
        position = pos(3,3,0),
        attachedFaces = { floor = true, north = true },
    }

    waterPipe:attach()

    assert(waterPipe.node ~= nil)
    assert(waterPipe.attachedFaces.floor == true)
    assert(waterPipe.attachedFaces.north == true)
end

----------------------------------------------------------------
-- Cardinal adjacency connectivity
----------------------------------------------------------------

do
    Registry.reset()

    local a = Pipe.WaterPipe.apply{
        id = "a",
        object = observed(),
        position = pos(10,10,0),
    }
    local b = Pipe.WaterPipe.apply{
        id = "b",
        object = observed(),
        position = pos(11,10,0), -- east of a
    }

    a:attach()
    b:attach()

    assert(a.node.neighbors["b"] ~= nil)
    assert(b.node.neighbors["a"] ~= nil)
    assert(a.node.network == b.node.network)
end

----------------------------------------------------------------
-- Derived floor connectivity helper
----------------------------------------------------------------

do
    Registry.reset()

    local p = Pipe.WaterPipe.apply{
        id = "p3",
        object = observed(),
        position = pos(4,4,0),
        attachedFaces = { floor = true },
    }

    local q = Pipe.WaterPipe.apply{
        id = "p4",
        object = observed(),
        position = pos(5,4,0), -- east
        attachedFaces = { floor = true },
    }

    p:attach()
    q:attach()

    p:recomputeFaceConnectivity()

    -- floor connectivity mask should include EAST
    assert(p.faceConnectivity.floor ~= 0)
end

print("pipe_entity_test OK")
