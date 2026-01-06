-- Registry.lua
-- Central registry for all Nodes.
--
-- Responsibilities:
-- - Index nodes by position
-- - Discover neighbors
-- - Create, merge, and split networks
--
-- This module owns the topology lifecycle but delegates
-- availability and resource semantics to Network/Node.
-- Registry.lua
--
-- TOPOLOGY INVARIANTS
--
-- 1. Networks are emergent and may legally contain a single node.
--    A node with no neighbors may still belong to a network.
--
-- 2. Isolation is defined by lack of neighbors, not by lack of a network.
--
-- 3. Networks are created when a node is registered and has no compatible
--    neighbors with an existing network.
--
-- 4. Networks are not destroyed when they drop to a single node.
--    They persist until explicitly merged or the node is unregistered.
--
-- These invariants are relied upon by:
-- - Pipe placement
-- - Valve topology gating
-- - Future adjacency and vertical connectivity
--
-- 5. Topology is CELL-scoped, not surface-scoped.
--    Exactly one Node may exist per (x, y, z, topologyResource).
--    Surface semantics are owned entirely by Entity, not Registry.

local Network = require("topology/net/Network")

local Registry = {}

----------------------------------------------------------------
-- Internal State
----------------------------------------------------------------

-- All nodes indexed by id
Registry.nodesById = {}

-- Nodes indexed by position key "x:y:z" -> { nodeId = node }
Registry.nodesByPos = {}

-- Nodes indexed by position and topologyResource:
-- nodesByPosAndResource["x:y:z"][topologyResource] = { nodeId = node }
Registry.nodesByPosAndResource = {}

----------------------------------------------------------------
-- Reset (test / dev support)
----------------------------------------------------------------

-- Clear all registry state.
-- Intended for tests and dev reloads only.
function Registry.reset()
    Registry.nodesById = {}
    Registry.nodesByPos = {}
    Registry.nodesByPosAndResource = {}
end

----------------------------------------------------------------
-- Utilities
----------------------------------------------------------------


local function posKey(pos)
    return string.format("%d:%d:%d", pos.x, pos.y, pos.z or 0)
end

-- Return any node at the given position (x,y,z).
-- If multiple nodes exist on that tile, returns the first one encountered.
function Registry.getNodeAtPosition(x, y, z)
    local key = string.format("%d:%d:%d", x, y, z or 0)
    local bucket = Registry.nodesByPos[key]
    if not bucket then return nil end

    for _, node in pairs(bucket) do
        return node
    end

    return nil
end

-- Return all nodes at the given position and resource.
-- Returns a table { nodeId = node } or nil.
function Registry.getNodesAtPosition(x, y, z, resource)
    local key = string.format("%d:%d:%d", x, y, z or 0)
    local byPos = Registry.nodesByPosAndResource[key]
    if not byPos then return nil end
    return byPos[resource]
end

-- Return true if any connector exists at the given position for the resource.
function Registry.hasConnectorAt(x, y, z, resource)
    local nodes = Registry.getNodesAtPosition(x, y, z, resource)
    if not nodes then return false end

    for _ in pairs(nodes) do
        return true
    end

    return false
end

----------------------------------------------------------------
-- Registration
----------------------------------------------------------------

-- Register a node and place it into an appropriate network.
function Registry.registerNode(node)
    assert(node ~= nil, "Node required")
    assert(node.id ~= nil, "Node id required")
    assert(node.position ~= nil, "Node position required")

    -- Disallow multiple nodes of the same topologyResource on the same tile
    local key = posKey(node.position)
    local topo = node.topologyResource

    if Registry.nodesByPosAndResource[key]
        and Registry.nodesByPosAndResource[key][topo]
    then
        error(string.format(
            "Topology violation: node for resource %s already exists at %s",
            tostring(topo),
            key
        ))
    end

    Registry.nodesById[node.id] = node

    Registry.nodesByPos[key] = Registry.nodesByPos[key] or {}
    Registry.nodesByPos[key][node.id] = node

    -- Topology-resource-scoped index
    Registry.nodesByPosAndResource[key] = Registry.nodesByPosAndResource[key] or {}
    Registry.nodesByPosAndResource[key][topo] = Registry.nodesByPosAndResource[key][topo] or {}
    Registry.nodesByPosAndResource[key][topo][node.id] = node

    -- Ensure the node always has a network (singleton networks are valid)
    if not node.network then
        local net = Network.new(topo)
        net:addNode(node)
    end

    -- Discover neighbors by cardinal adjacency (N/E/S/W), same Z and topologyResource
    local x = node.position.x
    local y = node.position.y
    local z = node.position.z

    local directions = {
        { dx =  0, dy = -1 }, -- North
        { dx =  1, dy =  0 }, -- East
        { dx =  0, dy =  1 }, -- South
        { dx = -1, dy =  0 }, -- West
    }

    for _, d in ipairs(directions) do
        local nx = x + d.dx
        local ny = y + d.dy

        local bucket = Registry.getNodesAtPosition(nx, ny, z, topo)
        if bucket then
            for _, other in pairs(bucket) do
                if other ~= node then
                    node:addNeighbor(other)
                    other:addNeighbor(node)

                    if node.network and other.network and node.network ~= other.network then
                        node.network:merge(other.network)
                    end
                end
            end
        end
    end
end

----------------------------------------------------------------
-- Deregistration
----------------------------------------------------------------

-- Remove a node and repair affected networks.
function Registry.unregisterNode(node)
    if not node or not Registry.nodesById[node.id] then return end

    Registry.nodesById[node.id] = nil

    local key = posKey(node.position)
    if Registry.nodesByPos[key] then
        Registry.nodesByPos[key][node.id] = nil
        -- Kahlua-safe emptiness check (do not rely on global `next`)
        local isEmpty = true
        for _ in pairs(Registry.nodesByPos[key]) do
            isEmpty = false
            break
        end

        if isEmpty then
            Registry.nodesByPos[key] = nil
        end
    end

    -- Remove from topology-resource-scoped index
    local topo = node.topologyResource
    if Registry.nodesByPosAndResource[key]
        and Registry.nodesByPosAndResource[key][topo]
    then
        Registry.nodesByPosAndResource[key][topo][node.id] = nil

        -- Clean up empty buckets
        local isEmpty = true
        for _ in pairs(Registry.nodesByPosAndResource[key][topo]) do
            isEmpty = false
            break
        end
        if isEmpty then
            Registry.nodesByPosAndResource[key][topo] = nil
        end

        -- Clean up position bucket if empty
        local posEmpty = true
        for _ in pairs(Registry.nodesByPosAndResource[key]) do
            posEmpty = false
            break
        end
        if posEmpty then
            Registry.nodesByPosAndResource[key] = nil
        end
    end

    -- Remove neighbor relationships (defensive: method may be absent)
    for _, other in pairs(node.neighbors or {}) do
        if other and type(other.removeNeighbor) == "function" then
            other:removeNeighbor(node)
        end
    end
    node.neighbors = {}

    -- Remove from network and split if needed
    local oldNetwork = node.network
    if oldNetwork then
        -- Remove node from network membership without assuming methods
        if oldNetwork.nodes then
            oldNetwork.nodes[node.id] = nil
        end
        node.network = nil

        -- Repair topology if the network still has nodes
        Registry._splitNetwork(oldNetwork)
    end
end

----------------------------------------------------------------
-- Network Repair
----------------------------------------------------------------

-- Split a network into connected components if it was fragmented.
function Registry._splitNetwork(network)
    if not network then return end

    local visited = {}
    local newNetworks = {}

    local function dfs(startNode)
        local stack = { startNode }
        local component = {}

        while #stack > 0 do
            local current = table.remove(stack)
            if not visited[current.id] then
                visited[current.id] = true
                component[#component + 1] = current
                for _, neighbor in pairs(current.neighbors) do
                    if not visited[neighbor.id] then
                        stack[#stack + 1] = neighbor
                    end
                end
            end
        end

        return component
    end

    for _, node in pairs(network.nodes) do
        if not visited[node.id] then
            local component = dfs(node)
            newNetworks[#newNetworks + 1] = component
        end
    end

    -- Reassign networks if split occurred
    if #newNetworks > 1 then
        for _, component in ipairs(newNetworks) do
            local newNet = Network.new(network.topologyResource)
            for _, node in ipairs(component) do
                newNet:addNode(node)
            end
        end
    end
end

----------------------------------------------------------------
-- Debug Helpers
----------------------------------------------------------------

function Registry.debugDump()
    print("Registry Debug Dump:")
    for id, node in pairs(Registry.nodesById) do
        print(string.format(
            "Node %s @ %s network=%s neighbors=%d",
            tostring(id),
            posKey(node.position),
            node.network and node.network.id or "<nil>",
            (function()
                local c = 0
                for _ in pairs(node.neighbors) do c = c + 1 end
                return c
            end)()
        ))
    end
end

return Registry