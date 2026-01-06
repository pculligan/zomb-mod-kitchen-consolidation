-- Entity.lua
-- Entity is a generic surface-attached topology participant.
--
-- Responsibilities:
-- - Owns intent: which surfaces (faces) this entity is attached to
-- - Registers exactly one Node with the topology layer
-- - Caches render-ready face connectivity derived from topology
--
-- Entity does NOT:
-- - Decide how faces are chosen (user intent)
-- - Encode pipe / riser / wall semantics
-- - Perform flow, allocation, or network logic
--
-- Concrete entity types express intent by setting `attachedFaces`.
-- The base Entity derives connectivity from that intent.

local Node = require("topology/net/Node")
local Registry = require("topology/net/Registry")

local Entity = {}
Entity.__index = Entity

----------------------------------------------------------------
-- Construction
----------------------------------------------------------------

-- opts table fields (required unless noted):
--   id               : unique identifier for this entity
--   topologyResource : Resource enum value (graph membership only)
--   position         : table {x=, y=, z=} identifying tile location
--   observed         : world object being observed (IsoObject, building, etc.)
--
-- Subclasses are expected to apply Storage / Provider / Consumer traits
-- after construction.
function Entity.new(opts)
    assert(type(opts) == "table", "Entity.new requires opts table")
    assert(opts.id ~= nil, "Entity id is required")
    assert(opts.topologyResource ~= nil, "topologyResource is required")
    assert(opts.position ~= nil, "Entity position is required")
    assert(opts.observed ~= nil, "Observed world object is required")

    local self = setmetatable({}, Entity)

    self.id = opts.id
    self.topologyResource = opts.topologyResource
    self.position = opts.position
    self.observed = opts.observed

    -- Capabilities container (populated by traits)
    self.capabilities = nil

    -- Node representing this entity in the topology graph
    self.node = Node.new(
        self.id,
        self.topologyResource,
        self.position,
        self
    )

    -- Lifecycle flags
    self.attached = false
    self.active = false

    -- Cached render-ready face connectivity.
    -- Bitmasks are derived state, not authoritative.
    -- Faces: floor, north, east, south, west
    self.faceConnectivity = {
        floor = 0,
        north = 0,
        east  = 0,
        south = 0,
        west  = 0,
    }

    -- Faces this entity is attached to (USER INTENT).
    --
    -- INVARIANTS:
    -- 1. Exactly ONE Entity exists per (x, y, z, topologyResource).
    -- 2. Surface coexistence is expressed via `attachedFaces` on that Entity,
    --    not via multiple entities.
    -- 3. The base Entity derives connectivity strictly from `attachedFaces`;
    --    no surface semantics exist in the topology layer.
    --
    -- Concrete types must populate this before attach().
    -- Valid faces: floor, north, east, south, west
    self.attachedFaces = {
        floor = false,
        north = false,
        east  = false,
        south = false,
        west  = false,
    }

    return self
end

----------------------------------------------------------------
-- Lifecycle
----------------------------------------------------------------

-- Attach this entity to the topology network.
-- Subclasses may override onAttach(), but must call Entity.attach(self)
function Entity:attach()
    if self.attached then return end

    self.attached = true

    -- Initial eligibility check
    if self:isEligible() then
        self.active = true
        self:onActivate()
    else
        self.active = false
    end

    self:onAttach()
end

-- Detach this entity from the topology network.
-- Always leaves the system in a clean state.
function Entity:detach()
    if not self.attached then return end

    if self.active then
        self:onDeactivate()
    end

    self.active = false
    self.attached = false

    self:onDetach()
end

----------------------------------------------------------------
-- Eligibility & Observation
----------------------------------------------------------------

-- Determine whether the observed object currently supports this entity.
-- Default implementation: observed object must exist.
-- Subclasses should override to enforce eligibility rules.
function Entity:isEligible()
    return self.observed ~= nil
end

----------------------------------------------------------------
-- Visual Connectivity (Derived, Render-Ready)
--
-- Entities declare intent by attaching to one or more faces.
-- The base class derives connectivity for those faces.
--
-- Rendering must never query topology directly.
-- All face connectivity is cached here at attach/detach time.
----------------------------------------------------------------

-- Whether this entity can visually connect to another entity.
-- Default: same topologyResource.
-- Subclasses may override.
function Entity:canVisuallyConnectTo(other)
    return other ~= nil and self.topologyResource == other.topologyResource
end

-- Compute the floor face connectivity bitmask based on local adjacency.
-- Bit layout: N=1, E=2, S=4, W=8
-- Same Z-level only.
function Entity:_computeFloorConnectivity()
    local mask = 0
    local x = self.position.x
    local y = self.position.y
    local z = self.position.z

    local neighbors = {
        { dx =  0, dy = -1, bit = 1 }, -- North
        { dx =  1, dy =  0, bit = 2 }, -- East
        { dx =  0, dy =  1, bit = 4 }, -- South
        { dx = -1, dy =  0, bit = 8 }, -- West
    }

    for _, n in ipairs(neighbors) do
        local nx = x + n.dx
        local ny = y + n.dy

        -- Query registry for entities at neighbor position for this topology
        local nodes = Registry.getNodesAtPosition(nx, ny, z, self.topologyResource)
        if nodes then
            for _, neighborNode in pairs(nodes) do
                local neighbor = neighborNode.entity
                if neighbor
                    and neighbor ~= self
                    and self:canVisuallyConnectTo(neighbor)
                    and neighbor:canVisuallyConnectTo(self)
                then
                    mask = mask + n.bit
                    break
                end
            end
        end
    end

    self.faceConnectivity.floor = mask
    return mask
end

-- Recompute connectivity for all faces this entity uses.
-- Base Entity supports FLOOR only.
-- Wall / vertical entities extend this.
function Entity:recomputeFaceConnectivity()
    -- Reset cached connectivity
    for face, _ in pairs(self.faceConnectivity) do
        self.faceConnectivity[face] = 0
    end

    -- Floor connectivity
    if self.attachedFaces.floor then
        self.faceConnectivity.floor = self:_computeFloorConnectivity()
    end
end

----------------------------------------------------------------
-- Activation Hooks
----------------------------------------------------------------

function Entity:onActivate()
    -- No-op by default
end

function Entity:onDeactivate()
    -- No-op by default
end

----------------------------------------------------------------
-- Local Face Connectivity Recompute Hooks
--
-- This helper recomputes this entity's face connectivity and
-- invalidates immediate neighbors so they can refresh derived
-- connectivity. No topology queries occur during rendering.
----------------------------------------------------------------

function Entity:_recomputeLocalVisualMasks()
    self:recomputeFaceConnectivity()

    local x = self.position.x
    local y = self.position.y
    local z = self.position.z

    local offsets = {
        { dx =  0, dy = -1 },
        { dx =  1, dy =  0 },
        { dx =  0, dy =  1 },
        { dx = -1, dy =  0 },
    }

    for _, o in ipairs(offsets) do
        local neighborNode = Registry.getNodeAtPosition(x + o.dx, y + o.dy, z)
        if neighborNode and neighborNode.entity then
            neighborNode.entity:recomputeFaceConnectivity()
        end
    end
end

-- Base attach recomputes connectivity for all faces this entity uses.
-- Subclasses must populate `attachedFaces` before attach().
function Entity:onAttach()
    Registry.registerNode(self.node)
    self:_recomputeLocalVisualMasks()
end

-- Called after detach()
function Entity:onDetach()
    Registry.unregisterNode(self.node)

    local x = self.position.x
    local y = self.position.y
    local z = self.position.z

    local offsets = {
        { dx =  0, dy = -1 },
        { dx =  1, dy =  0 },
        { dx =  0, dy =  1 },
        { dx = -1, dy =  0 },
    }

    for _, o in ipairs(offsets) do
        local neighborNode = Registry.getNodeAtPosition(x + o.dx, y + o.dy, z)
        if neighborNode and neighborNode.entity then
            neighborNode.entity:recomputeFaceConnectivity()
        end
    end

    return nil
end

----------------------------------------------------------------
-- Inspection & Debug
----------------------------------------------------------------

function Entity:getInspectionData()
    return {
        id = self.id,
        topologyResource = self.topologyResource,
        position = self.position,
        attached = self.attached,
        active = self.active,
        hasObservedObject = self.observed ~= nil,
        networkId = self.node.network and self.node.network.id or nil,
        capabilities = self.capabilities,
    }
end



return Entity
