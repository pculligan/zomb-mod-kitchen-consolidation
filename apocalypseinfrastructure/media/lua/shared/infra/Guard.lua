-- Guard.lua
-- Instance-based guard/validation helpers with injectable Logger.


local Logger = require("infra/Logger")
local Guard = {}

----------------------------------------------------------------
-- Instance
----------------------------------------------------------------

local GuardInstance = {}
GuardInstance.__index = GuardInstance

function GuardInstance.new(logger)
    local self = setmetatable({}, GuardInstance)
    self.log = logger or Logger
    return self
end

function GuardInstance:failOn(cond, msg)
    if not cond then return false end
    if msg then self.log.error(msg) end
    return true
end

function GuardInstance:warnOn(cond, msg)
    if not cond then return false end
    if msg then self.log.warn(msg) end
    return true
end

function GuardInstance:assured(cond, msg)
    if cond then return true end
    if msg then self.log.error(msg) end
    return false
end

----------------------------------------------------------------
-- Factory
----------------------------------------------------------------

function Guard.new(logger)
    return GuardInstance.new(logger)
end

----------------------------------------------------------------
-- Backward-compatible default instance
----------------------------------------------------------------

local _default = GuardInstance.new(Logger)

Guard.failOn = function(cond, msg)
    return _default:failOn(cond, msg)
end

Guard.warnOn = function(cond, msg)
    return _default:warnOn(cond, msg)
end

Guard.assured = function(cond, msg)
    return _default:assured(cond, msg)
end

return Guard