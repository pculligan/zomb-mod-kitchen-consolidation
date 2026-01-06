-- RainBarrelConnector.lua
-- Connector for vanilla rain collector barrels.
--
-- This is a minimal, first connector whose sole responsibility is to:
-- - Observe a rain barrel world object
-- - Expose a Water-providing node
-- - Register/unregister with the Registry cleanly

local WaterProvider = require("flow/Water/WaterProvider")
local Registry      = require("topology/net/Registry")

-- Runtime helpers (singleton)

local Runtime = require("infra/Runtime")
local log     = Runtime.Logger
local guard   = Runtime.Guard

local WaterStore = require("flow/Water/WaterStore")

local RainBarrelConnector = {}
RainBarrelConnector.__index = RainBarrelConnector
setmetatable(RainBarrelConnector, { __index = WaterProvider })

----------------------------------------------------------------
-- Construction
----------------------------------------------------------------

-- opts:
--   id       : unique connector id
--   object   : IsoObject for the rain barrel
--   position : { x, y, z }
function RainBarrelConnector.new(opts)
    guard.assured(opts ~= nil, "RainBarrelConnector.new requires opts")
    guard.assured(opts.object ~= nil, "RainBarrelConnector requires an observed object")
    guard.assured(opts.position ~= nil, "RainBarrelConnector requires a position")

    local self = WaterProvider.new({
        id = opts.id,
        position = opts.position,
        observed = opts.object,
        capabilities = {
            consume = false,
            store   = true,
        }
    })

    setmetatable(self, RainBarrelConnector)

    -- Bind WaterStore to IsoObject state
    WaterStore.apply(self, {
        capacity = 400,   -- vanilla rain barrel capacity
        initial  = self.observed:getWaterAmount() or 0
    })

    -- Override storage mutation to sync with IsoObject
    local baseDrain = self.drain
    function self:drain(resource, amount)
        local ok, reason = baseDrain(self, resource, amount)
        if ok then
            self.observed:setWaterAmount(self._stored)
        end
        return ok, reason
    end

    return self
end

----------------------------------------------------------------
-- Eligibility
----------------------------------------------------------------

-- A rain barrel is eligible if the observed object still exists.
-- We intentionally do NOT inspect water amount yet.
function RainBarrelConnector:isEligible()
    return self.observed ~= nil
end

----------------------------------------------------------------
-- Lifecycle Hooks
----------------------------------------------------------------

function RainBarrelConnector:onAttach()
    log.debug("Attaching RainBarrelConnector connector " .. tostring(self.id))
    Registry.registerNode(self.node)
end

function RainBarrelConnector:onDetach()
    log.debug("Detaching RainBarrelConnector connector " .. tostring(self.id))
    Registry.unregisterNode(self.node)
end

function RainBarrelConnector:onActivate()
    log.debug("RainBarrelConnector activated " .. tostring(self.id))
end

function RainBarrelConnector:onDeactivate()
    log.debug("RainBarrelConnector deactivated " .. tostring(self.id))
end

----------------------------------------------------------------
-- Export
----------------------------------------------------------------

return RainBarrelConnector
