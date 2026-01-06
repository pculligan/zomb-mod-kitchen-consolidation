-- ClientInit.lua
-- Guaranteed client-side bootstrap for Apocalypse Infrastructure.
-- Uses Runtime singleton helpers for logging and configuration.

-- NOTE:
-- We intentionally use raw `print()` only for the very first line,
-- before Runtime is available, to prove bootstrap execution.
local Runtime = require("infra/Runtime")
local dbg = Runtime.Logger.debug
print("[Apocalypse Infrastructure] ClientInit.lua loaded")

Events.OnGameStart.Add(function()
    -- Load Runtime singleton (auto-executed from /)

    if not Runtime then
        print("[Apocalypse Infrastructure] FATAL: Runtime not available at OnGameStart")
        return
    end



    dbg("OnGameStart fired")

    dbg("Dev enabled = " .. tostring(Runtime.Settings and Runtime.Settings.devEnabled))

    if Runtime.Settings.devEnabled then
        dbg("Loading DevAPI")
        require("dev/DevAPI")
    else
        dbg("Dev mode disabled")
    end
end)