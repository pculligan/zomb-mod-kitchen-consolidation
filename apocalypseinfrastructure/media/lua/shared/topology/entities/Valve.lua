-- Valve.lua
-- Resource‑agnostic, surface‑attached topology gate.
--
-- A Valve expresses user intent by attaching to exactly ONE surface
-- (floor or a specific wall face). It gates connectivity on that
-- surface when closed, and allows connectivity when open.
--
-- Valves do not replace pipes. They occupy a single surface slot
-- and gate adjacency between exactly two attachments on that surface.

local Entity   = require("topology/entities/Entity")
local Registry = require("topology/net/Registry")

local Runtime = require("infra/Runtime")
local log     = Runtime.Logger
local guard   = Runtime.Guard

local Valve = {}
Valve.__index = Valve
setmetatable(Valve, { __index = Entity })

-- opts:
--   id               : unique entity id
--   object           : observed world object (valve tile anchor)
--   position         : { x, y, z }
--   topologyResource : Resource enum value
--   open             : boolean (default true)
function Valve.new(opts)
    guard.assured(opts ~= nil, "Valve.new requires opts")
    guard.assured(opts.object ~= nil, "Valve requires an observed object")
    guard.assured(opts.position ~= nil, "Valve requires a position")
    guard.assured(opts.topologyResource ~= nil, "Valve requires a topologyResource")

    local self = Entity.new{
        id = opts.id,
        topologyResource = opts.topologyResource,
        position = opts.position,
        observed = opts.object,
    }

    setmetatable(self, Valve)

    -- Intent: the single surface this valve occupies.
    --
    -- INVARIANTS:
    -- 1. Exactly one Entity exists per (x, y, z, topologyResource).
    -- 2. A Valve occupies exactly ONE surface on that Entity.
    -- 3. That surface gates exactly TWO adjacencies.
    -- 4. Placement/preview code enforces surface choice and adjacency count.
    --
    -- The Valve itself never infers topology or placement legality.
    self.attachedFaces = {
        floor = false,
        north = false,
        east  = false,
        south = false,
        west  = false,
    }

    -- Contract:
    -- Exactly ONE attachedFaces entry must be true before attach().
    -- Placement/preview code is responsible for enforcing this.

    -- Valve state
    self._open = (opts.open ~= false)

    return self
end

----------------------------------------------------------------
-- Canonical entry point (apply == construct)
----------------------------------------------------------------

function Valve.apply(opts)
    return Valve.new(opts)
end

----------------------------------------------------------------
-- Valve semantics
----------------------------------------------------------------

function Valve:isOpen()
    return self._open == true
end

-- Eligibility determines whether this valve participates in topology.
-- When closed, the valve removes its gated adjacency by
-- unregistering its node from the topology.
function Valve:isEligible()
    return self.observed ~= nil and self._open == true
end

----------------------------------------------------------------
-- State transitions
----------------------------------------------------------------

-- Toggle valve state (topology change)
function Valve:setOpen(open)
    local desired = (open == true)
    if self._open == desired then return end

    self._open = desired

    if desired then
        log.debug("Valve opened " .. tostring(self.id) .. " (surface‑gated)")
        Registry.registerNode(self.node)
    else
        log.debug("Valve closed " .. tostring(self.id) .. " (surface‑gated)")
        Registry.unregisterNode(self.node)
    end

    self:_recomputeLocalVisualMasks()
end

----------------------------------------------------------------
-- Lifecycle overrides (topology gating)
----------------------------------------------------------------

-- Lifecycle: attach/detach toggle whether this valve participates
-- in topology based on its open/closed state.
-- Connectivity is always derived by Entity from attachedFaces.
function Valve:onAttach()
    -- Participate in topology only if open
    if self._open then
        Registry.registerNode(self.node)
    end
    self:_recomputeLocalVisualMasks()
end

function Valve:onDetach()
    -- Always remove from topology on detach
    Registry.unregisterNode(self.node)
    self:_recomputeLocalVisualMasks()
end

-- Lifecycle hooks (no topology side effects)
function Valve:onActivate()
    log.debug("Valve activated " .. tostring(self.id) ..
        " open=" .. tostring(self._open))
end

function Valve:onDeactivate()
    log.debug("Valve deactivated " .. tostring(self.id))
end

----------------------------------------------------------------
-- Resource-specific thin wrappers (Option-2)
----------------------------------------------------------------

local Resource = require("core/domain/Resource")

local WaterValve = {}
function WaterValve.apply(opts)
    opts = opts or {}
    opts.topologyResource = Resource.WATER
    return Valve.apply(opts)
end
Valve.WaterValve = WaterValve

local FuelValve = {}
function FuelValve.apply(opts)
    opts = opts or {}
    opts.topologyResource = Resource.FUEL
    return Valve.apply(opts)
end
Valve.FuelValve = FuelValve

local PropaneValve = {}
function PropaneValve.apply(opts)
    opts = opts or {}
    opts.topologyResource = Resource.PROPANE
    return Valve.apply(opts)
end
Valve.PropaneValve = PropaneValve

local PumpableWaterValve = {}
function PumpableWaterValve.apply(opts)
    opts = opts or {}
    opts.topologyResource = Resource.PUMPABLE_WATER
    return Valve.apply(opts)
end
Valve.PumpableWaterValve = PumpableWaterValve

-- Electricity valves are presented to players as switches,
-- but behave identically at the topology level.
local ElectricitySwitch = {}
function ElectricitySwitch.apply(opts)
    opts = opts or {}
    opts.topologyResource = Resource.ELECTRICITY
    return Valve.apply(opts)
end
Valve.ElectricitySwitch = ElectricitySwitch

return Valve
