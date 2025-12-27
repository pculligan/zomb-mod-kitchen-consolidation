-- Init.lua
-- Initialization and optional auto-consolidation hook
-- Auto-consolidation is OFF by default and must be explicitly enabled via SandboxVars.


local Runtime = require("Runtime/Runtime")

local assured = Runtime.Guard.assured
local failOn = Runtime.Guard.failOn
local warnOn = Runtime.Guard.warnOn


local FoodRegistry = require("Domain/FoodRegistry")

-- Prime FoodType registry from known sources (each module must return a list)
local sources = {
    "Food/Vanilla",
    "Food/CookingTime",
    "Food/FoodPreservationPlus",
    "Food/KitchenConsolidation",
}

for _, modName in ipairs(sources) do
    local ok, data = pcall(require, modName)
    failOn(not ok, "FoodRegistry: failed to load " .. modName .. " : " .. tostring(data))
    assured(type(data) == "table", "FoodRegistry: module did not return a table: " .. modName)
    FoodRegistry.instance:registerAll(data)
end
