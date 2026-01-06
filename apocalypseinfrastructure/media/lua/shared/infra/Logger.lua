-- Logger.lua
-- Instance-based logger with backward-compatible default instance.
--
-- Usage (recommended):
--   local Logger = require("Runtime.Logger")
--   local log = Logger.new("ApocalypseInfrastructure", Logger.LOGLEVELS.DEBUG)
--   log.debug("hello")
--
-- Backward compatibility:
--   local Logger = require("Runtime.Logger")
--   Logger.debug("hello")  -- uses default instance

local Logger = {}

-- ---------------------------------------------------------------------------
-- Levels
-- ---------------------------------------------------------------------------

local LOGLEVELS = {
  TRACE = 1,
  DEBUG = 2,
  WARN  = 3,
  ERROR = 4
}

-- ---------------------------------------------------------------------------
-- Instance
-- ---------------------------------------------------------------------------

local LoggerInstance = {}
LoggerInstance.__index = LoggerInstance

local function _noop(_) end

local function makePrinters(prefix)
    return {
        print = function(msg)
            print(prefix .. tostring(msg))
        end,
        warn = function(msg)
            print(prefix .. "[WARN] " .. tostring(msg))
        end,
        error = function(msg)
            print(prefix .. "[ERROR] " .. tostring(msg))
        end
    }
end

function LoggerInstance:_applyLevel(level)
    local p = self._printers

    if level == LOGLEVELS.TRACE then
        self.trace = p.print
        self.debug = p.print
        self.warn  = p.warn
        self.error = p.error
    elseif level == LOGLEVELS.DEBUG then
        self.trace = _noop
        self.debug = p.print
        self.warn  = p.warn
        self.error = p.error
    elseif level == LOGLEVELS.WARN then
        self.trace = _noop
        self.debug = _noop
        self.warn  = p.warn
        self.error = p.error
    elseif level == LOGLEVELS.ERROR then
        self.trace = _noop
        self.debug = _noop
        self.warn  = _noop
        self.error = p.error
    else
        -- default WARN
        self.trace = _noop
        self.debug = _noop
        self.warn  = p.warn
        self.error = p.error
    end

    self.level = level
end

function LoggerInstance:setLogLevel(level)
    self:_applyLevel(level)
end

function LoggerInstance:setLogLevelFromString(level)
    if type(level) ~= "string" then
        self:setLogLevel(LOGLEVELS.WARN)
        return
    end

    local upper = string.upper(level)

    if upper == "TRACE" then
        self:setLogLevel(LOGLEVELS.TRACE)
    elseif upper == "DEBUG" then
        self:setLogLevel(LOGLEVELS.DEBUG)
    elseif upper == "WARN" then
        self:setLogLevel(LOGLEVELS.WARN)
    elseif upper == "ERROR" then
        self:setLogLevel(LOGLEVELS.ERROR)
    else
        self:setLogLevel(LOGLEVELS.WARN)
    end
end

-- ---------------------------------------------------------------------------
-- Factory
-- ---------------------------------------------------------------------------

function Logger.new(name, level)
    local prefix = "[" .. tostring(name) .. "] "

    local inst = setmetatable({}, LoggerInstance)
    inst.name = name
    inst._printers = makePrinters(prefix)

    -- Apply log level (supports enum or string)
    if type(level) == "string" then
        inst:setLogLevelFromString(level)
    elseif type(level) == "number" then
        inst:_applyLevel(level)
    else
        inst:_applyLevel(LOGLEVELS.WARN)
    end

    return inst
end

-- ---------------------------------------------------------------------------
-- Backward-compatible default instance
-- ---------------------------------------------------------------------------

local _default = Logger.new("ApocalypseInfrastructure", LOGLEVELS.DEBUG)

-- Proxy default instance methods onto Logger table
Logger.trace = function(msg) _default.trace(msg) end
Logger.debug = function(msg) _default.debug(msg) end
Logger.warn  = function(msg) _default.warn(msg) end
Logger.error = function(msg) _default.error(msg) end

function Logger.setLogLevel(level)
    _default:setLogLevel(level)
end

function Logger.setLogLevelFromString(level)
    _default:setLogLevelFromString(level)
end

-- Deprecated compatibility wrapper
function Logger.setDebug(enabled)
    if enabled then
        Logger.setLogLevel(LOGLEVELS.DEBUG)
    else
        Logger.setLogLevel(LOGLEVELS.WARN)
    end
end

Logger.LOGLEVELS = LOGLEVELS

return Logger