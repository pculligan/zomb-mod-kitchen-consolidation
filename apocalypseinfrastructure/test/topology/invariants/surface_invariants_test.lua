local Pipe     = require("topology/entities/Pipe")
local Registry = require("topology/net/Registry")
local Resource = require("core/domain/Resource")

print("surface_invariants_test")

local function observed()
    return {}
end

local function pos(x,y,z)
    return { x=x, y=y, z=z or 0 }
end

----------------------------------------------------------------
-- One entity per cell per resource; multiple surfaces allowed
----------------------------------------------------------------

do
    Registry.reset()

    local p = Pipe.WaterPipe.apply{
        id = "p-multi",
        object = observed(),
        position = pos(1,1,0),
        attachedFaces = { floor = true, north = true },
    }

    p:attach()

    assert(p.node ~= nil)
    assert(p.attachedFaces.floor == true)
    assert(p.attachedFaces.north == true)
end

----------------------------------------------------------------
-- Reusing the same surface does not create extra nodes
-- (placement layer is responsible for rejecting duplicates)
----------------------------------------------------------------

do
    Registry.reset()

    local p = Pipe.WaterPipe.apply{
        id = "p-dup",
        object = observed(),
        position = pos(2,2,0),
        attachedFaces = { floor = true },
    }

    p:attach()
    local node = p.node

    -- Re-attaching with the same surface intent is a no-op at the Entity level
    p.attachedFaces.floor = true
    p:attach()

    assert(p.node == node)
end

----------------------------------------------------------------
-- Different surfaces on same cell do not create extra nodes
----------------------------------------------------------------

do
    Registry.reset()

    local p = Pipe.WaterPipe.apply{
        id = "p-node",
        object = observed(),
        position = pos(3,3,0),
        attachedFaces = { floor = true },
    }

    p:attach()
    local node = p.node

    -- Extend intent to another surface
    p.attachedFaces.north = true
    p:recomputeFaceConnectivity()

    assert(p.node == node)
end

----------------------------------------------------------------
-- Surface intent does not affect Registry adjacency
----------------------------------------------------------------

do
    Registry.reset()

    local a = Pipe.WaterPipe.apply{
        id = "a",
        object = observed(),
        position = pos(4,4,0),
        attachedFaces = { floor = true },
    }

    local b = Pipe.WaterPipe.apply{
        id = "b",
        object = observed(),
        position = pos(5,4,0),
        attachedFaces = { north = true },
    }

    a:attach()
    b:attach()

    -- Registry adjacency is positional only
    assert(a.node.neighbors["b"] ~= nil)
    assert(b.node.neighbors["a"] ~= nil)
end

print("surface_invariants_test OK")
