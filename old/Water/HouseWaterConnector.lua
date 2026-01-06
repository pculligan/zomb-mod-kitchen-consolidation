

-- HouseWaterConnector.lua
-- Connector representing a house-level water endpoint.
-- This connector is capability-driven and may consume and/or provide water
-- depending on configuration. Initially implemented as consume-only.

local WaterConsumer = require("flow/Water/WaterConsumer")

local Runtime = require("infra/Runtime")
local log     = Runtime.Logger
local guard   = Runtime.Guard

local HouseWaterConnector = {}
HouseWaterConnector.__index = HouseWaterConnector
setmetatable(HouseWaterConnector, { __index = WaterConsumer })

----------------------------------------------------------------
-- Construction
----------------------------------------------------------------

-- opts:
--   id       : unique connector id
--   object   : observed world object (sink, fixture, building anchor)
--   position : { x, y, z }
--   capabilities (optional):
--       consume : boolean (default true)
--       provide : boolean (default false)
--       store   : boolean (default false)
function HouseWaterConnector.new(opts)
    guard.assured(opts ~= nil, "HouseWaterConnector.new requires opts")
    guard.assured(opts.object ~= nil, "HouseWaterConnector requires an observed object")
    guard.assured(opts.position ~= nil, "HouseWaterConnector requires a position")

    local caps = opts.capabilities or {}

    local self = WaterConsumer.new({
        id = opts.id,
        object = opts.object,
        position = opts.position,
        capabilities = {
            consume = (caps.consume ~= false),
            provide = (caps.provide == true),
            store   = (caps.store == true),
        }
    })

    setmetatable(self, HouseWaterConnector)
    return self
end

----------------------------------------------------------------
-- Eligibility
----------------------------------------------------------------

-- Eligible if the observed object still exists.
-- This can later be refined to check object type.
function HouseWaterConnector:isEligible()
    return self.observed ~= nil
end

----------------------------------------------------------------
-- Lifecycle Hooks
----------------------------------------------------------------

function HouseWaterConnector:onActivate()
    log.debug("HouseWaterConnector activated " .. tostring(self.id))
end

function HouseWaterConnector:onDeactivate()
    log.debug("HouseWaterConnector deactivated " .. tostring(self.id))
end

----------------------------------------------------------------
-- Consumption API
----------------------------------------------------------------

-- Consume a given amount of water from the network.
-- Returns: planResult, applyResult
-- Explicit and event-driven.
function HouseWaterConnector:use(amount)
    guard.assured(type(amount) == "number" and amount > 0,
        "HouseWaterConnector:use requires positive amount")

    if not self.capabilities.consume then
        return {
            ok = false,
            reason = "consume_disabled",
            requested = amount,
            fulfilled = 0,
        }, nil
    end

    local planResult = self:requestWater(amount)
    if not planResult.ok then
        return planResult, nil
    end

    local applyResult = self:applyPlan(planResult)
    return planResult, applyResult
end

----------------------------------------------------------------
-- Export
----------------------------------------------------------------

return HouseWaterConnector