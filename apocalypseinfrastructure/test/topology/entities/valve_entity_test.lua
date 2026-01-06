local Valve    = require("topology/entities/Valve")
local Pipe     = require("topology/entities/Pipe")
local Registry = require("topology/net/Registry")
local Resource = require("core/domain/Resource")

print("valve_entity_test")

local function observed()
    return {}
end

local function pos(x,y,z)
    return { x=x, y=y, z=z or 0 }
end

----------------------------------------------------------------
-- Default open state
----------------------------------------------------------------

do
    local v = Valve.WaterValve.apply{
        id = "v1",
        object = observed(),
        position = pos(1,1,0),
    }

    assert(v:isOpen() == true)
end

----------------------------------------------------------------
-- Surface intent invariant (one entity per cell per resource)
----------------------------------------------------------------

do
    Registry.reset()

    -- Attach a pipe entity to the cell
    local p = Pipe.WaterPipe.apply{
        id = "p1",
        object = observed(),
        position = pos(2,2,0),
        attachedFaces = { floor = true },
    }
    p:attach()

    -- Attempting to attach a valve as a second entity in the same cell
    -- for the same resource must fail
    local v = Valve.WaterValve.apply{
        id = "v1",
        object = observed(),
        position = pos(2,2,0),
        attachedFaces = { north = true },
    }

    local ok, err = pcall(function() v:attach() end)
    assert(ok == false)
end

----------------------------------------------------------------
-- Topology gating via open / closed state
----------------------------------------------------------------

do
    Registry.reset()

    -- a -- v -- b  (horizontal floor run)
    local a = Pipe.WaterPipe.apply{
        id = "a",
        object = observed(),
        position = pos(5,5,0),
        attachedFaces = { floor = true },
    }
    local v = Valve.WaterValve.apply{
        id = "v",
        object = observed(),
        position = pos(6,5,0),
        attachedFaces = { floor = true },
        open = false, -- start closed
    }
    local b = Pipe.WaterPipe.apply{
        id = "b",
        object = observed(),
        position = pos(7,5,0),
        attachedFaces = { floor = true },
    }

    a:attach()
    v:attach()
    b:attach()

    -- Closed valve removes adjacency
    assert(a.node.neighbors["v"] == nil)
    assert(b.node.neighbors["v"] == nil)
    assert(v.node.network == nil)

    -- Open valve restores adjacency
    v:setOpen(true)

    assert(a.node.neighbors["v"] ~= nil)
    assert(v.node.neighbors["a"] ~= nil)
    assert(v.node.neighbors["b"] ~= nil)
    assert(b.node.neighbors["v"] ~= nil)

    -- All three share a network
    assert(a.node.network == v.node.network)
    assert(v.node.network == b.node.network)
end

print("valve_entity_test OK")
