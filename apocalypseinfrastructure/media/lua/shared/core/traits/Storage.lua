
-- Storage.lua
-- Trait: resource-agnostic storage semantics
-- Populates Capabilities.stores and provides drain/get APIs

local Resource   = require("core/domain/Resource")
local Capability = require("core/domain/Capability")

local StoreCapability = Capability.StoreCapability
local Capabilities    = Capability.Capabilities

local Storage = {}
Storage.__index = Storage

----------------------------------------------------------------
-- Mixin application
----------------------------------------------------------------
-- opts:
--   capability : StoreCapability (required)
--   observed   : backing IsoObject (optional)
--   getAmount  : function(observed) -> number (optional)
--   setAmount  : function(observed, number) (optional)
function Storage.apply(target, opts)
    assert(target, "Storage.apply requires target")
    assert(opts and opts.capability, "Storage.apply requires opts.capability")

    if not target.capabilities then
        target.capabilities = Capabilities.new()
    end

    local cap = opts.capability
    target.capabilities:addStore(cap)

    target.observed   = opts.observed or target.observed
    target._getAmount = opts.getAmount
    target._setAmount = opts.setAmount

    -- Bind API
    target.getAvailable = Storage.getAvailable
    target.isDrainable  = Storage.isDrainable
    target.drain        = Storage.drain
    target.getStored    = Storage.getStored
    target.getCapacity  = Storage.getCapacity
end

----------------------------------------------------------------
-- Store API (capability-backed)
----------------------------------------------------------------

function Storage:getAvailable(resource)
    local cap = self.capabilities and self.capabilities:getStore(resource)
    if not cap then return 0 end

    if self.observed and self._getAmount then
        local v = self._getAmount(self.observed)
        if v ~= nil then cap.current = v end
    end

    return cap.current
end

function Storage:isDrainable(resource)
    local cap = self.capabilities and self.capabilities:getStore(resource)
    if not cap then return false end

    if self.observed and self._getAmount then
        local v = self._getAmount(self.observed)
        if v ~= nil then cap.current = v end
    end

    return cap.current > 0
end

function Storage:drain(resource, amount)
    local cap = self.capabilities and self.capabilities:getStore(resource)
    if not cap then return false, "unsupported_resource" end

    if cap.current < amount then
        amount = cap.current
    end

    cap.current = cap.current - amount

    if self.observed and self._setAmount then
        self._setAmount(self.observed, cap.current)
    end

    return true, nil
end

function Storage:getStored(resource)
    local cap = self.capabilities and self.capabilities:getStore(resource)
    return cap and cap.current or 0
end

function Storage:getCapacity(resource)
    local cap = self.capabilities and self.capabilities:getStore(resource)
    return cap and cap.capacity or 0
end

----------------------------------------------------------------
-- Resource-specific wrappers (Option-2)
----------------------------------------------------------------

function Storage.water(target, opts)
    opts = opts or {}
    return Storage.apply(target, {
        capability = Capability.WaterStoreCapability(opts),
        observed   = opts.observed,
        getAmount  = function(o) return o.getWaterAmount and o:getWaterAmount() end,
        setAmount  = function(o,v) if o.setWaterAmount then o:setWaterAmount(v) end end,
    })
end

function Storage.fuel(target, opts)
    opts = opts or {}
    return Storage.apply(target, {
        capability = Capability.FuelStoreCapability(opts),
        observed   = opts.observed,
        getAmount  = function(o) return o.getFuelAmount and o:getFuelAmount() end,
        setAmount  = function(o,v) if o.setFuelAmount then o:setFuelAmount(v) end end,
    })
end

function Storage.propane(target, opts)
    opts = opts or {}
    return Storage.apply(target, {
        capability = Capability.PropaneStoreCapability(opts),
        observed   = opts.observed,
        getAmount  = function(o) return o.getPropaneAmount and o:getPropaneAmount() end,
        setAmount  = function(o,v) if o.setPropaneAmount then o:setPropaneAmount(v) end end,
    })
end

function Storage.electricity(target, opts)
    opts = opts or {}
    return Storage.apply(target, {
        capability = Capability.ElectricityStoreCapability(opts),
    })
end

function Storage.pumpableWater(target, opts)
    opts = opts or {}
    return Storage.apply(target, {
        capability = Capability.PumpableWaterStoreCapability(opts),
    })
end

return Storage
