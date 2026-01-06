local Resource = require("core/domain/Resource")

-- Capability.lua
--
-- Concrete capability model used by Entities and Traits.
-- Capabilities are structured, resource-keyed relationships between an entity
-- and a resource. Traits populate these; entities own the container.

----------------------------------------------------------------
-- TRAIT COMPOSITION INVARIANT
--
-- Ordering matters and is enforced:
--
--   1. Storage MUST be applied before Provider
--   2. Provider MUST be applied before Consumer
--
-- Rationale:
--   - Storage establishes authoritative quantity state
--   - Provider exposes stored resources to the network
--   - Consumer requests resources via allocation
--
-- Capabilities encode this dependency structurally:
--   stores   -> provides -> consumes
----------------------------------------------------------------

----------------------------------------------------------------
-- Capability structs
----------------------------------------------------------------

local ProviderCapability = {}
ProviderCapability.__index = ProviderCapability

function ProviderCapability.new(opts)
    assert(opts and opts.resource, "ProviderCapability requires resource")

    return setmetatable({
        resource = opts.resource,          -- Resource.*
        enabled  = opts.enabled ~= false,  -- default true
        priority = opts.priority or 0,     -- allocation hint
        meta     = opts.meta or {},        -- resource-specific metadata
    }, ProviderCapability)
end


local ConsumerCapability = {}
ConsumerCapability.__index = ConsumerCapability

function ConsumerCapability.new(opts)
    assert(opts and opts.resource, "ConsumerCapability requires resource")

    return setmetatable({
        resource = opts.resource,
        enabled  = opts.enabled ~= false,
        meta     = opts.meta or {},
    }, ConsumerCapability)
end


local StoreCapability = {}
StoreCapability.__index = StoreCapability

function StoreCapability.new(opts)
    assert(opts and opts.resource, "StoreCapability requires resource")

    return setmetatable({
        resource = opts.resource,
        capacity = opts.capacity or 0,
        current  = opts.current or 0,
        meta     = opts.meta or {},
    }, StoreCapability)
end

----------------------------------------------------------------
-- Provider metadata (resource-specific)
----------------------------------------------------------------

local WaterProviderMeta = {}
WaterProviderMeta.__index = WaterProviderMeta

function WaterProviderMeta.new(opts)
    opts = opts or {}
    return setmetatable({
        quality = opts.quality or "clean",   -- clean | tainted | toxic
        temperature = opts.temperature,
    }, WaterProviderMeta)
end


local FuelProviderMeta = {}
FuelProviderMeta.__index = FuelProviderMeta

function FuelProviderMeta.new(opts)
    opts = opts or {}
    return setmetatable({
        octane = opts.octane or 87,
        ethanol = opts.ethanol or 0,
    }, FuelProviderMeta)
end


local PropaneProviderMeta = {}
PropaneProviderMeta.__index = PropaneProviderMeta

function PropaneProviderMeta.new(opts)
    opts = opts or {}
    return setmetatable({
        pressure = opts.pressure or 0,
    }, PropaneProviderMeta)
end


local ElectricityProviderMeta = {}
ElectricityProviderMeta.__index = ElectricityProviderMeta

function ElectricityProviderMeta.new(opts)
    opts = opts or {}
    return setmetatable({
        voltage = opts.voltage or 120,
        phase   = opts.phase or "single",
    }, ElectricityProviderMeta)
end


local PumpableWaterProviderMeta = {}
PumpableWaterProviderMeta.__index = PumpableWaterProviderMeta

function PumpableWaterProviderMeta.new(opts)
    opts = opts or {}
    return setmetatable({
        depth = opts.depth or 0,
        contamination = opts.contamination or "raw",
    }, PumpableWaterProviderMeta)
end

----------------------------------------------------------------
-- Consumer metadata (resource-specific)
----------------------------------------------------------------

local WaterConsumerMeta = {}
WaterConsumerMeta.__index = WaterConsumerMeta

function WaterConsumerMeta.new(opts)
    opts = opts or {}
    return setmetatable({
        filtration = opts.filtration or "none",
    }, WaterConsumerMeta)
end


local FuelConsumerMeta = {}
FuelConsumerMeta.__index = FuelConsumerMeta

function FuelConsumerMeta.new(opts)
    opts = opts or {}
    return setmetatable({
        efficiency = opts.efficiency or 1.0,
        burnRate   = opts.burnRate,
    }, FuelConsumerMeta)
end


local PropaneConsumerMeta = {}
PropaneConsumerMeta.__index = PropaneConsumerMeta

function PropaneConsumerMeta.new(opts)
    opts = opts or {}
    return setmetatable({
        burnRate = opts.burnRate or 0,
        efficiency = opts.efficiency or 1.0,
    }, PropaneConsumerMeta)
end


local ElectricityConsumerMeta = {}
ElectricityConsumerMeta.__index = ElectricityConsumerMeta

function ElectricityConsumerMeta.new(opts)
    opts = opts or {}
    return setmetatable({
        watts = opts.watts or 0,
        surge = opts.surge or 0,
    }, ElectricityConsumerMeta)
end

----------------------------------------------------------------
-- Store metadata (resource-specific)
----------------------------------------------------------------

local WaterStoreMeta = {}
WaterStoreMeta.__index = WaterStoreMeta

function WaterStoreMeta.new(opts)
    opts = opts or {}
    return setmetatable({
        frozen = opts.frozen or false,
        contaminated = opts.contaminated or false,
    }, WaterStoreMeta)
end


local FuelStoreMeta = {}
FuelStoreMeta.__index = FuelStoreMeta

function FuelStoreMeta.new(opts)
    opts = opts or {}
    return setmetatable({
        volatile = opts.volatile or false,
        evaporation = opts.evaporation or 0,
    }, FuelStoreMeta)
end


local PropaneStoreMeta = {}
PropaneStoreMeta.__index = PropaneStoreMeta

function PropaneStoreMeta.new(opts)
    opts = opts or {}
    return setmetatable({
        pressure = opts.pressure or 0,
        volatile = opts.volatile or false,
    }, PropaneStoreMeta)
end


local ElectricityStoreMeta = {}
ElectricityStoreMeta.__index = ElectricityStoreMeta

function ElectricityStoreMeta.new(opts)
    opts = opts or {}
    return setmetatable({
        chemistry = opts.chemistry or "lead-acid",
        maxCharge = opts.maxCharge or 0,
    }, ElectricityStoreMeta)
end


local PumpableWaterStoreMeta = {}
PumpableWaterStoreMeta.__index = PumpableWaterStoreMeta

function PumpableWaterStoreMeta.new(opts)
    opts = opts or {}
    return setmetatable({
        pressure = opts.pressure or 0,
    }, PumpableWaterStoreMeta)
end

----------------------------------------------------------------
-- Capability container
----------------------------------------------------------------

local Capabilities = {}
Capabilities.__index = Capabilities

function Capabilities.new()
    return setmetatable({
        provides = {},  -- [resource] = ProviderCapability
        consumes = {},  -- [resource] = ConsumerCapability
        stores   = {},  -- [resource] = StoreCapability
    }, Capabilities)
end

function Capabilities:addProvider(cap)
    assert(getmetatable(cap) == ProviderCapability, "addProvider requires ProviderCapability")
    self.provides[cap.resource] = cap
end

function Capabilities:getProvider(resource)
    return self.provides[resource]
end

function Capabilities:addConsumer(cap)
    assert(getmetatable(cap) == ConsumerCapability, "addConsumer requires ConsumerCapability")
    self.consumes[cap.resource] = cap
end

function Capabilities:getConsumer(resource)
    return self.consumes[resource]
end

function Capabilities:addStore(cap)
    assert(getmetatable(cap) == StoreCapability, "addStore requires StoreCapability")
    self.stores[cap.resource] = cap
end

function Capabilities:getStore(resource)
    return self.stores[resource]
end

function Capabilities:hasStore(resource)
    return self.stores[resource] ~= nil
end

function Capabilities:hasProvider(resource)
    return self.provides[resource] ~= nil
end

function Capabilities:hasAnyProvider()
    return next(self.provides) ~= nil
end

----------------------------------------------------------------
-- Capability convenience constructors
----------------------------------------------------------------

local function WaterProviderCapability(opts)
    opts = opts or {}
    return ProviderCapability.new{
        resource = Resource.WATER,
        enabled  = opts.enabled,
        priority = opts.priority,
        meta     = WaterProviderMeta.new(opts.meta),
    }
end

local function FuelProviderCapability(opts)
    opts = opts or {}
    return ProviderCapability.new{
        resource = Resource.FUEL,
        enabled  = opts.enabled,
        priority = opts.priority,
        meta     = FuelProviderMeta.new(opts.meta),
    }
end

local function PropaneProviderCapability(opts)
    opts = opts or {}
    return ProviderCapability.new{
        resource = Resource.PROPANE,
        enabled  = opts.enabled,
        priority = opts.priority,
        meta     = PropaneProviderMeta.new(opts.meta),
    }
end

local function ElectricityProviderCapability(opts)
    opts = opts or {}
    return ProviderCapability.new{
        resource = Resource.ELECTRICITY,
        enabled  = opts.enabled,
        priority = opts.priority,
        meta     = ElectricityProviderMeta.new(opts.meta),
    }
end

local function PumpableWaterProviderCapability(opts)
    opts = opts or {}
    return ProviderCapability.new{
        resource = Resource.PUMPABLE_WATER,
        enabled  = opts.enabled,
        priority = opts.priority,
        meta     = PumpableWaterProviderMeta.new(opts.meta),
    }
end


local function WaterConsumerCapability(opts)
    opts = opts or {}
    return ConsumerCapability.new{
        resource = Resource.WATER,
        enabled  = opts.enabled,
        meta     = WaterConsumerMeta.new(opts.meta),
    }
end

local function FuelConsumerCapability(opts)
    opts = opts or {}
    return ConsumerCapability.new{
        resource = Resource.FUEL,
        enabled  = opts.enabled,
        meta     = FuelConsumerMeta.new(opts.meta),
    }
end

local function PropaneConsumerCapability(opts)
    opts = opts or {}
    return ConsumerCapability.new{
        resource = Resource.PROPANE,
        enabled  = opts.enabled,
        meta     = PropaneConsumerMeta.new(opts.meta),
    }
end

local function ElectricityConsumerCapability(opts)
    opts = opts or {}
    return ConsumerCapability.new{
        resource = Resource.ELECTRICITY,
        enabled  = opts.enabled,
        meta     = ElectricityConsumerMeta.new(opts.meta),
    }
end


local function WaterStoreCapability(opts)
    opts = opts or {}
    return StoreCapability.new{
        resource = Resource.WATER,
        capacity = opts.capacity,
        current  = opts.current,
        meta     = WaterStoreMeta.new(opts.meta),
    }
end

local function FuelStoreCapability(opts)
    opts = opts or {}
    return StoreCapability.new{
        resource = Resource.FUEL,
        capacity = opts.capacity,
        current  = opts.current,
        meta     = FuelStoreMeta.new(opts.meta),
    }
end

local function PropaneStoreCapability(opts)
    opts = opts or {}
    return StoreCapability.new{
        resource = Resource.PROPANE,
        capacity = opts.capacity,
        current  = opts.current,
        meta     = PropaneStoreMeta.new(opts.meta),
    }
end

local function ElectricityStoreCapability(opts)
    opts = opts or {}
    return StoreCapability.new{
        resource = Resource.ELECTRICITY,
        capacity = opts.capacity,
        current  = opts.current,
        meta     = ElectricityStoreMeta.new(opts.meta),
    }
end

local function PumpableWaterStoreCapability(opts)
    opts = opts or {}
    return StoreCapability.new{
        resource = Resource.PUMPABLE_WATER,
        capacity = opts.capacity,
        current  = opts.current,
        meta     = PumpableWaterStoreMeta.new(opts.meta),
    }
end

----------------------------------------------------------------
-- Exports
----------------------------------------------------------------

return {
    Capabilities = Capabilities,

    ProviderCapability = ProviderCapability,
    ConsumerCapability = ConsumerCapability,
    StoreCapability    = StoreCapability,

    -- Provider metadata
    WaterProviderMeta   = WaterProviderMeta,
    FuelProviderMeta    = FuelProviderMeta,
    PropaneProviderMeta = PropaneProviderMeta,
    ElectricityProviderMeta = ElectricityProviderMeta,
    PumpableWaterProviderMeta = PumpableWaterProviderMeta,

    -- Consumer metadata
    WaterConsumerMeta   = WaterConsumerMeta,
    FuelConsumerMeta    = FuelConsumerMeta,
    PropaneConsumerMeta = PropaneConsumerMeta,
    ElectricityConsumerMeta = ElectricityConsumerMeta,

    -- Store metadata
    WaterStoreMeta      = WaterStoreMeta,
    FuelStoreMeta       = FuelStoreMeta,
    PropaneStoreMeta    = PropaneStoreMeta,
    ElectricityStoreMeta    = ElectricityStoreMeta,
    PumpableWaterStoreMeta  = PumpableWaterStoreMeta,

    -- Provider capability helpers
    WaterProviderCapability   = WaterProviderCapability,
    FuelProviderCapability    = FuelProviderCapability,
    PropaneProviderCapability = PropaneProviderCapability,
    ElectricityProviderCapability = ElectricityProviderCapability,
    PumpableWaterProviderCapability = PumpableWaterProviderCapability,

    -- Consumer capability helpers
    WaterConsumerCapability   = WaterConsumerCapability,
    FuelConsumerCapability    = FuelConsumerCapability,
    PropaneConsumerCapability = PropaneConsumerCapability,
    ElectricityConsumerCapability = ElectricityConsumerCapability,

    -- Store capability helpers
    WaterStoreCapability      = WaterStoreCapability,
    FuelStoreCapability       = FuelStoreCapability,
    PropaneStoreCapability    = PropaneStoreCapability,
    ElectricityStoreCapability    = ElectricityStoreCapability,
    PumpableWaterStoreCapability  = PumpableWaterStoreCapability,
}