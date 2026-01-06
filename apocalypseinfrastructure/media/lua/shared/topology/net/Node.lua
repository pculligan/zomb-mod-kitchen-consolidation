-- Node.lua
-- Represents a single entity endpoint in a topology network.
-- Nodes are pure topology objects and must not snapshot capability state.

local Node = {}
Node.__index = Node

-- Create a new node
-- id: unique string or number
-- topologyResource: Resource enum value (network graph key)
-- position: table {x=, y=, z=}
-- entity: owning entity (provides capabilities, behavior)
function Node.new(id, topologyResource, position, entity)
    assert(id ~= nil, "Node id is required")
    assert(topologyResource ~= nil, "Node topologyResource is required")
    assert(position ~= nil, "Node position is required")
    assert(entity ~= nil, "Node entity is required")

    local self = setmetatable({}, Node)

    self.id = id
    self.topologyResource = topologyResource
    self.position = position
    self.entity = entity

    -- Network this node currently belongs to (set by Network)
    self.network = nil

    -- Neighbor node ids (adjacency list)
    self.neighbors = {}

    return self
end

-- Add a neighbor relationship (undirected)
function Node:addNeighbor(otherNode)
    assert(otherNode ~= nil, "Neighbor node required")
    self.neighbors[otherNode.id] = otherNode
end

-- Remove a neighbor relationship
function Node:removeNeighbor(otherNode)
    if otherNode then
        self.neighbors[otherNode.id] = nil
    end
end

return Node
