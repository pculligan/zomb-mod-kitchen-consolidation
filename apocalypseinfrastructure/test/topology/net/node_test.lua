local Resource = require("core/domain/Resource")
local Node     = require("topology/net/Node")
local Capability = require("core/domain/Capability")

print("node_test")

-- Minimal fake entity
local function newEntity(id)
    return {
        id = id,
        capabilities = Capability.Capabilities.new(),
    }
end

----------------------------------------------------------------
-- Test: Node construction binds entity
----------------------------------------------------------------

do
    local e = newEntity("entity-1")

    local node = Node.new(
        "node-1",
        Resource.WATER,
        { x = 1, y = 2, z = 0 },
        e
    )

    assert(node.id == "node-1")
    assert(node.topologyResource == Resource.WATER)
    assert(node.entity ~= nil)
    assert(node.entity == e)
end

----------------------------------------------------------------
-- Test: Node does not snapshot capabilities
----------------------------------------------------------------

do
    local e = newEntity("entity-2")

    local node = Node.new(
        "node-2",
        Resource.WATER,
        { x = 0, y = 0, z = 0 },
        e
    )

    -- Mutate capabilities after node creation
    e.capabilities:addProvider(
        Capability.WaterProviderCapability{}
    )

    assert(
        node.entity.capabilities:getProvider(Resource.WATER) ~= nil,
        "Node should see live capability changes via entity reference"
    )
end

----------------------------------------------------------------
-- Test: Neighbor add/remove
----------------------------------------------------------------

do
    local e1 = newEntity("entity-A")
    local e2 = newEntity("entity-B")

    local n1 = Node.new("node-A", Resource.WATER, {x=0,y=0,z=0}, e1)
    local n2 = Node.new("node-B", Resource.WATER, {x=1,y=0,z=0}, e2)

    n1:addNeighbor(n2)
    assert(n1.neighbors["node-B"] ~= nil)

    n1:removeNeighbor(n2)
    assert(n1.neighbors["node-B"] == nil)
end

----------------------------------------------------------------
-- Test: addNeighbor is idempotent (no duplication)
----------------------------------------------------------------

do
    local e1 = newEntity("entity-idem-A")
    local e2 = newEntity("entity-idem-B")

    local n1 = Node.new("node-idem-A", Resource.WATER, {x=0,y=0,z=0}, e1)
    local n2 = Node.new("node-idem-B", Resource.WATER, {x=1,y=0,z=0}, e2)

    n1:addNeighbor(n2)
    n1:addNeighbor(n2)

    local count = 0
    for _ in pairs(n1.neighbors) do count = count + 1 end
    assert(count == 1)
    assert(n1.neighbors["node-idem-B"] == n2)
end

----------------------------------------------------------------
-- Test: Node identity is independent of entity shape
-- (node never inspects entity fields)
----------------------------------------------------------------

do
    local e1 = newEntity("entity-shape-A")
    e1.attachedFaces = { floor = true, north = true }
    e1.faceConnectivity = { floor = 7, north = 0, east = 0, south = 0, west = 0 }

    local e2 = newEntity("entity-shape-B")
    e2.attachedFaces = { east = true }
    e2.faceConnectivity = { floor = 0, north = 0, east = 3, south = 0, west = 0 }

    local n1 = Node.new("node-shape-A", Resource.WATER, {x=0,y=0,z=0}, e1)
    local n2 = Node.new("node-shape-B", Resource.WATER, {x=1,y=0,z=0}, e2)

    -- Neighbor ops do not depend on entity fields
    n1:addNeighbor(n2)
    assert(n1.neighbors["node-shape-B"] == n2)
end

print("node_test OK")