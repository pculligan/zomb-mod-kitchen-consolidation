-- Provider.lua
-- Trait: marks an entity as a resource provider.
-- Providers expose availability and drain semantics for a resource.
-- Actual storage is delegated to an attached Store trait (if present).

local Resource = require("core/domain/Resource")
local Capability = require("core/domain/Capability")

local ProviderCapability = Capability.ProviderCapability
local Capabilities = Capability.Capabilities

local Provider = {}
Provider.__index = Provider

----------------------------------------------------------------
-- Apply Provider role (generic)
----------------------------------------------------------------
-- opts:
--   capability : ProviderCapability (required)
function Provider.apply(target, opts)
    assert(target, "Provider.apply requires target")
    assert(opts and opts.capability, "Provider.apply requires opts.capability")

    -- Ensure entity has a Capabilities container
    if not target.capabilities then
        target.capabilities = Capabilities.new()
    end

    local cap = opts.capability
    assert(
        target.capabilities:hasStore(cap.resource),
        "Provider.apply requires Storage for resource before Provider"
    )

    -- Register provider capability
    target.capabilities:addProvider(cap)

    -- Attach provider-facing API (delegates via capabilities)
    target.isDrainable  = Provider.isDrainable
    target.getAvailable = Provider.getAvailable
    target.drain        = Provider.drain
end

----------------------------------------------------------------
-- Provider API (delegates to Store capability)
----------------------------------------------------------------

function Provider:isDrainable(resource)
    local cap = self.capabilities and self.capabilities:getProvider(resource)
    if not cap or not cap.enabled then
        return false
    end

    -- Prefer Store semantics if present
    local store = self.capabilities:getStore(resource)
    if store then
        return store.current and store.current > 0
    end

    return false
end

function Provider:getAvailable(resource)
    local cap = self.capabilities and self.capabilities:getProvider(resource)
    if not cap or not cap.enabled then
        return 0
    end

    local store = self.capabilities:getStore(resource)
    if store then
        return store.current or 0
    end

    return 0
end

function Provider:drain(resource, amount)
    local cap = self.capabilities and self.capabilities:getProvider(resource)
    if not cap or not cap.enabled then
        return false, "not_provider"
    end

    local store = self.capabilities:getStore(resource)
    if not store then
        return false, "no_store"
    end

    if store.current < amount then
        amount = store.current
    end

    store.current = store.current - amount
    return true, nil
end

----------------------------------------------------------------
-- Resource-specific wrappers (Option-2)
----------------------------------------------------------------

function Provider.water(target, opts)
    opts = opts or {}
    return Provider.apply(target, {
        capability = Capability.WaterProviderCapability(opts)
    })
end

function Provider.fuel(target, opts)
    opts = opts or {}
    return Provider.apply(target, {
        capability = Capability.FuelProviderCapability(opts)
    })
end

function Provider.propane(target, opts)
    opts = opts or {}
    return Provider.apply(target, {
        capability = Capability.PropaneProviderCapability(opts)
    })
end

function Provider.electricity(target, opts)
    opts = opts or {}
    return Provider.apply(target, {
        capability = Capability.ElectricityProviderCapability(opts)
    })
end

function Provider.pumpableWater(target, opts)
    opts = opts or {}
    return Provider.apply(target, {
        capability = Capability.PumpableWaterProviderCapability(opts)
    })
end

return Provider