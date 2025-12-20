-- KitchenConsolidation_Init.lua
-- Initialization and optional auto-consolidation hook
-- Auto-consolidation is OFF by default and must be explicitly enabled via SandboxVars.

local Util = require("KitchenConsolidation_Util")
local ConsolidateAction = require("KitchenConsolidation_ConsolidateAction")

if type(ConsolidateAction) ~= "table" or type(ConsolidateAction.new) ~= "function" then
    Util.warn("AutoConsolidate: ConsolidateAction module is not valid; disabling auto-consolidation for this session")
    return
end

-- Minimum seconds between auto-consolidation attempts per player
local AUTO_COOLDOWN_SEC = 3

local function isAutoConsolidateEnabled()
    return SandboxVars
        and SandboxVars.KitchenConsolidation
        and SandboxVars.KitchenConsolidation.AutoConsolidate == true
end

