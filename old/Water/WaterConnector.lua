-- WaterConnector.lua
-- Thin water specialization of BaseConnector

local BaseConnector = require("flow/BaseConnector")

local WaterConnector = {}
WaterConnector.__index = WaterConnector
setmetatable(WaterConnector, { __index = BaseConnector })

function WaterConnector.new(opts)
    opts.resource = "Water"
    local self = BaseConnector.new(opts)
    setmetatable(self, WaterConnector)
    return self
end

return WaterConnector