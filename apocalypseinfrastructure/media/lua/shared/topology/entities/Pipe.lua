-- Pipe.lua
-- Resource-agnostic surface-attached pipe entity.
--
-- A Pipe expresses user intent by attaching to ONE OR MORE surfaces
-- of a cell (floor or specific wall faces).
--
-- Connectivity (horizontal, vertical appearance, junctions) is
-- fully derived from topology and cached on the entity.
--
-- Pipe is a passive component: it does not gate flow or mutate
-- topology beyond adjacency.

local Entity   = require("topology/entities/Entity")
local Registry = require("topology/net/Registry")
local Resource = require("core/domain/Resource")

local Runtime = require("infra/Runtime")
local log     = Runtime.Logger
local guard   = Runtime.Guard

local Pipe = {}
Pipe.__index = Pipe
setmetatable(Pipe, { __index = Entity })

-- opts:
--   id               : unique entity id
--   object           : observed world object (tile anchor)
--   position         : { x, y, z }
--   topologyResource : Resource enum value
function Pipe.new(opts)
    guard.assured(opts ~= nil, "Pipe.new requires opts")
    guard.assured(opts.object ~= nil, "Pipe requires an observed object")
    guard.assured(opts.position ~= nil, "Pipe requires a position")
    guard.assured(opts.topologyResource ~= nil, "Pipe requires a topologyResource")

    local self = Entity.new{
        id = opts.id,
        topologyResource = opts.topologyResource,
        position = opts.position,
        observed = opts.object,
    }

    setmetatable(self, Pipe)

    -- Intent: surfaces this pipe is attached to.
    -- Placement/UI code may provide this explicitly.
    -- Default to floor-only for backwards compatibility.
    if opts.attachedFaces then
        self.attachedFaces = opts.attachedFaces
    else
        self.attachedFaces.floor = true
    end

    return self
end

----------------------------------------------------------------
-- Canonical entry point (apply == construct)
----------------------------------------------------------------

function Pipe.apply(opts)
    return Pipe.new(opts)
end

----------------------------------------------------------------
-- Eligibility & placement
----------------------------------------------------------------

-- Pipes are always eligible while the observed object exists.
-- Pipes do not gate or remove adjacency; they only add connectivity.
function Pipe:isEligible()
    return self.observed ~= nil
end

----------------------------------------------------------------
-- Visual helpers
----------------------------------------------------------------

-- Straight pipe detection based on derived FLOOR connectivity.
-- Used only when this pipe is attached to the floor surface.
function Pipe:isStraightPipe()
    local mask = self.faceConnectivity.floor
    return mask == 5 or mask == 10
end

----------------------------------------------------------------
-- Lifecycle hooks (no topology side effects).
-- Connectivity is derived at attach/detach time.
----------------------------------------------------------------

function Pipe:onActivate()
    log.debug("Pipe activated " .. tostring(self.id))
end

function Pipe:onDeactivate()
    log.debug("Pipe deactivated " .. tostring(self.id))
end

----------------------------------------------------------------
-- Resource-specific thin wrappers
----------------------------------------------------------------

local WaterPipe = {}
function WaterPipe.apply(opts)
    opts = opts or {}
    opts.topologyResource = Resource.WATER
    return Pipe.apply(opts)
end
Pipe.WaterPipe = WaterPipe

local FuelPipe = {}
function FuelPipe.apply(opts)
    opts = opts or {}
    opts.topologyResource = Resource.FUEL
    return Pipe.apply(opts)
end
Pipe.FuelPipe = FuelPipe

local PropanePipe = {}
function PropanePipe.apply(opts)
    opts = opts or {}
    opts.topologyResource = Resource.PROPANE
    return Pipe.apply(opts)
end
Pipe.PropanePipe = PropanePipe

local PumpableWaterPipe = {}
function PumpableWaterPipe.apply(opts)
    opts = opts or {}
    opts.topologyResource = Resource.PUMPABLE_WATER
    return Pipe.apply(opts)
end
Pipe.PumpableWaterPipe = PumpableWaterPipe

local ElectricityWire = {}
function ElectricityWire.apply(opts)
    opts = opts or {}
    opts.topologyResource = Resource.ELECTRICITY
    return Pipe.apply(opts)
end
Pipe.ElectricityWire = ElectricityWire

return Pipe
