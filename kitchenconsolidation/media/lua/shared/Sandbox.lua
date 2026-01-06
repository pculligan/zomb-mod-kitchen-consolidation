-- ---------------------------------------------------------------------------
-- Kitchen Consolidation – Sandbox Options
-- ---------------------------------------------------------------------------

require "SandboxOptions"
local Logger = require("infra/Logger")

-- Declare sandbox option
SandboxOptions.newOption(
    "KitchenConsolidation",
    "LogLevel",
    SandboxOptions.ConfigType.Enum,
    {
        "WARN",
        "DEBUG",
        "TRACE"
    },
    1 -- default index → WARN
)

-- Apply sandbox log level as early as possible
Events.OnGameBoot.Add(function()
    if SandboxVars
        and SandboxVars.KitchenConsolidation
        and SandboxVars.KitchenConsolidation.LogLevel then

        Logger.setLogLevelFromString(
            SandboxVars.KitchenConsolidation.LogLevel
        )
    else
        -- Fallback safety
        Logger.setLogLevel(Logger.LOGLEVELS.WARN)
    end
end)
