local Logger = {}

-- ---------------------------------------------------------------------------
-- Logging (zero‑overhead when disabled)
-- ---------------------------------------------------------------------------

local LOGLEVELS = {
  TRACE = 1,
  DEBUG = 2,
  WARN  = 3,
  ERROR = 4
}

local function _noop(_) end
local function _print(msg)
    print("[KitchenConsolidation] " .. tostring(msg))
end
local function _warn(msg)
    print("[KitchenConsolidation][WARN] " .. tostring(msg))
end
local function _error(msg)
    print("[KitchenConsolidation][ERROR] " .. tostring(msg))
end

Logger.trace = _noop
Logger.debug = _noop
Logger.warn  = _warn
Logger.error = _error

function Logger.setLogLevel(level)
    if level == LOGLEVELS.TRACE then
        Logger.trace = _print
        Logger.debug = _print
        Logger.warn  = _warn
        Logger.error = _error
    elseif level == LOGLEVELS.DEBUG then
        Logger.trace = _noop
        Logger.debug = _print
        Logger.warn  = _warn
        Logger.error = _error
    elseif level == LOGLEVELS.WARN then
        Logger.trace = _noop
        Logger.debug = _noop
        Logger.warn  = _warn
        Logger.error = _error
    elseif level == LOGLEVELS.ERROR then
        Logger.trace = _noop
        Logger.debug = _noop
        Logger.warn  = _noop
        Logger.error = _error
    else
        -- Unknown level, default to WARN
        Logger.trace = _noop
        Logger.debug = _noop
        Logger.warn  = _warn
        Logger.error = _error
    end
end

-- Default log level is WARN
Logger.setLogLevel(LOGLEVELS.DEBUG)

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