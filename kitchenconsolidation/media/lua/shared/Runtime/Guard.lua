local GUARD = {}
local Log = require("infra/Logger")

function GUARD.failOn(cond, msg)
    if not cond then return false end
    if msg then Log.error(msg) end
    return true
end

function GUARD.warnOn(cond, msg)
    if not cond then return false end
    if msg then Log.warn(msg) end
    return true
end

function GUARD.assured(cond, msg)
    if cond then return true end
    if msg then Log.error(msg) end
    return false
end


return GUARD