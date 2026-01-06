local Entity = require("topology/entities/Entity")
local Registry   = require("topology/net/Registry")
local Resource   = require("core/domain/Resource")

print("base_entity_test")

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function newObserved()
    return { alive = true }
end

local function newEntity(id, x, y, z)
    return Entity.new{
        id = id,
        topologyResource = Resource.WATER,
        position = { x = x, y = y, z = z or 0 },
        observed = newObserved(),
    }
end

----------------------------------------------------------------
-- Test: construction invariants
----------------------------------------------------------------

do
    local e = newEntity("e1", 1, 1, 0)

    assert(e.id == "e1")
    assert(e.topologyResource == Resource.WATER)
    assert(e.node ~= nil)
    assert(e.node.entity == e)
    assert(e.node.topologyResource == Resource.WATER)
    assert(type(e.attachedFaces) == "table")
end

----------------------------------------------------------------
-- Test: attach registers node, detach unregisters
----------------------------------------------------------------

do
    Registry.reset()

    local e = newEntity("e2", 2, 2, 0)

    e:attach()

    assert(e.attached == true)
    assert(e.node.network ~= nil)
    assert(Registry.nodesById[e.id] == e.node)

    e:detach()

    assert(e.attached == false)
    assert(e.node.network == nil)
    assert(Registry.nodesById[e.id] == nil)
end

----------------------------------------------------------------
-- Test: attach/detach idempotence
----------------------------------------------------------------

do
    Registry.reset()

    local e = newEntity("e3", 3, 3, 0)

    e:attach()
    e:attach()

    assert(e.attached == true)
    assert(Registry.nodesById[e.id] ~= nil)

    e:detach()
    e:detach()

    assert(e.attached == false)
    assert(Registry.nodesById[e.id] == nil)
end

----------------------------------------------------------------
-- Test: eligibility gating
----------------------------------------------------------------

do
    Registry.reset()

    local e = newEntity("e4", 4, 4, 0)

    function e:isEligible()
        return false
    end

    e:attach()

    assert(e.attached == true)
    assert(e.active == false)
    assert(Registry.nodesById[e.id] ~= nil)
end

----------------------------------------------------------------
-- Test: face connectivity recompute does not error
----------------------------------------------------------------

do
    Registry.reset()

    local e1 = newEntity("e5a", 5, 5, 0)
    local e2 = newEntity("e5b", 6, 5, 0)

    e1:attach()
    e2:attach()

    -- recompute should not error
    e1:recomputeFaceConnectivity()
    e2:recomputeFaceConnectivity()

    -- base Entity exposes faceConnectivity with all faces
    assert(type(e1.faceConnectivity) == "table")
    assert(type(e1.faceConnectivity.floor) == "number")
    assert(type(e1.faceConnectivity.north) == "number")
    assert(type(e1.faceConnectivity.east) == "number")
    assert(type(e1.faceConnectivity.south) == "number")
    assert(type(e1.faceConnectivity.west) == "number")

    e1:detach()
    e2:detach()
end

print("base_entity_test OK")
