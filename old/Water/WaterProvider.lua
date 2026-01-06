-- WaterProvider.lua
-- Role semantics for water-providing connectors

local WaterConnector = require("flow/Water/WaterConnector")

local WaterProvider = {}
WaterProvider.__index = WaterProvider
setmetatable(WaterProvider, { __index = WaterConnector })

function WaterProvider.new(opts)
    opts.capabilities = opts.capabilities or {}
    opts.capabilities.provide = true
    return WaterConnector.new(opts)
end

return WaterProvider