-- Network.lua
-- Represents a connected set of nodes sharing a topology resource.
-- Networks own topology only; they do not interpret capabilities.
-- Network.lua
--
-- A Network represents a connected topology group.
-- Networks may contain a single node and are not destroyed
-- automatically when isolated.

local Network = {}
Network.__index = Network

-- Create a new network for a given topology resource
-- topologyResource: Resource enum value
-- id: optional unique identifier
function Network.new(topologyResource, id)
    assert(topologyResource ~= nil, "Network topologyResource is required")

    local self = setmetatable({}, Network)

    self.id = id or tostring({})
    self.topologyResource = topologyResource

    -- Nodes keyed by node.id
    self.nodes = {}

    return self
end

-- Add a node to this network
function Network:addNode(node)
    assert(node ~= nil, "Node required")
    assert(node.topologyResource == self.topologyResource,
        "Node topologyResource does not match network topologyResource")

    self.nodes[node.id] = node
    node.network = self
end

-- Remove a node from this network
function Network:removeNode(node)
    if node and self.nodes[node.id] then
        self.nodes[node.id] = nil
        node.network = nil
    end
end

-- Merge another network into this one
-- The other network is consumed
function Network:merge(other)
    assert(other ~= nil, "Other network required")
    assert(other.topologyResource == self.topologyResource,
        "Cannot merge networks of different topologyResource")

    for _, node in pairs(other.nodes) do
        self:addNode(node)
    end

    other.nodes = {}
end

-- Debug helper
function Network:debugSummary()
    local count = 0
    for _ in pairs(self.nodes) do count = count + 1 end

    return string.format(
        "Network[%s] topologyResource=%s nodes=%d",
        self.id,
        tostring(self.topologyResource),
        count
    )
end

return Network
