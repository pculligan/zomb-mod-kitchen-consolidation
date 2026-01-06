local Resource = require("core/domain/Resource")
local Network  = require("topology/net/Network")
local Node     = require("topology/net/Node")
local Capability = require("core/domain/Capability")

print("network_test")

-- Minimal fake entity
local function newEntity(id)
    return {
        id = id,
        capabilities = Capability.Capabilities.new(),
    }
end

----------------------------------------------------------------
-- Test: Network construction
----------------------------------------------------------------

do
    local net = Network.new(Resource.WATER)

    assert(net ~= nil)
    assert(net.topologyResource == Resource.WATER)
end

----------------------------------------------------------------
-- Test: Add/remove node
----------------------------------------------------------------

do
    local e = newEntity("entity-1")
    local node = Node.new(
        "node-1",
        Resource.WATER,
        {x=0,y=0,z=0},
        e
    )

    local net = Network.new(Resource.WATER)
    net:addNode(node)

    assert(node.network == net)
    assert(net.nodes["node-1"] ~= nil)

    net:removeNode(node)
    assert(node.network == nil)
    assert(net.nodes["node-1"] == nil)
end

----------------------------------------------------------------
-- Test: Merge networks
----------------------------------------------------------------

do
    local net1 = Network.new(Resource.WATER)
    local net2 = Network.new(Resource.WATER)

    local e1 = newEntity("entity-1")
    local e2 = newEntity("entity-2")

    local n1 = Node.new("node-1", Resource.WATER, {x=0,y=0,z=0}, e1)
    local n2 = Node.new("node-2", Resource.WATER, {x=1,y=0,z=0}, e2)

    net1:addNode(n1)
    net2:addNode(n2)

    net1:merge(net2)

    assert(net1.nodes["node-1"] ~= nil)
    assert(net1.nodes["node-2"] ~= nil)
    assert(n2.network == net1)
end

----------------------------------------------------------------
-- Test: Reject mismatched topologyResource
----------------------------------------------------------------

do
    local net = Network.new(Resource.WATER)
    local e = newEntity("entity-X")

    local badNode = Node.new(
        "node-X",
        Resource.FUEL,
        {x=0,y=0,z=0},
        e
    )

    local ok = pcall(function()
        net:addNode(badNode)
    end)

    assert(ok == false, "Network accepted node with mismatched topologyResource")
end

----------------------------------------------------------------
-- Test: Network ignores entity surface intent entirely
-- (topology-only container; never inspects entity fields)
----------------------------------------------------------------

do
    local net = Network.new(Resource.WATER)

    local e1 = newEntity("entity-surface-a")
    e1.attachedFaces = { floor = true }
    local e2 = newEntity("entity-surface-b")
    e2.attachedFaces = { north = true, east = true, floor = false }

    local n1 = Node.new("node-surface-a", Resource.WATER, {x=0,y=0,z=0}, e1)
    local n2 = Node.new("node-surface-b", Resource.WATER, {x=1,y=0,z=0}, e2)

    net:addNode(n1)
    net:addNode(n2)

    assert(n1.network == net)
    assert(n2.network == net)
    assert(net.nodes["node-surface-a"] ~= nil)
    assert(net.nodes["node-surface-b"] ~= nil)
end

----------------------------------------------------------------
-- Test: Network merge is independent of entity mutation
-- (mutating entity intent does not affect membership)
----------------------------------------------------------------

do
    local net1 = Network.new(Resource.WATER)
    local net2 = Network.new(Resource.WATER)

    local e1 = newEntity("entity-m1")
    e1.attachedFaces = { floor = true }
    local e2 = newEntity("entity-m2")
    e2.attachedFaces = { north = true }

    local n1 = Node.new("node-m1", Resource.WATER, {x=0,y=0,z=0}, e1)
    local n2 = Node.new("node-m2", Resource.WATER, {x=1,y=0,z=0}, e2)

    net1:addNode(n1)
    net2:addNode(n2)

    -- mutate intent after network membership
    e1.attachedFaces = { west = true }
    e2.attachedFaces = { floor = true, south = true }

    net1:merge(net2)

    assert(n1.network == net1)
    assert(n2.network == net1)
    assert(net1.nodes["node-m1"] ~= nil)
    assert(net1.nodes["node-m2"] ~= nil)
end

print("network_test OK")
