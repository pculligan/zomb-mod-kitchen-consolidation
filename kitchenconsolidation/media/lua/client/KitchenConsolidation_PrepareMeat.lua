-- KitchenConsolidation_PrepareMeat.lua
-- Client-side context menu action for bulk meat preparation
-- Inventory mutation is delegated to a timed action

local Util = require("KitchenConsolidation_Util")
local Meats = require("KitchenConsolidation_Meats")
require("KitchenConsolidation_PrepareMeatAction")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function isValidMeatSource(item)
    if not item or not instanceof(item, "Food") then return false end
    return Meats.SOURCES[item:getFullType()] == true
end

local function collectMeatSources(items)
    local results = {}
    local seen = {}

    for _, item in ipairs(items) do
        if item and not seen[item] and isValidMeatSource(item) then
            seen[item] = true
            table.insert(results, item)
        end
    end

    return results
end

-- ---------------------------------------------------------------------------
-- Context Menu Hook
-- ---------------------------------------------------------------------------

local function addPrepareMeatOption(player, context, worldobjects, test)
    if test then return true end    

    -- Flatten worldobjects into inventory items
    local rawItems = {}
    for _, v in ipairs(worldobjects) do
        if type(v) == "table" and v.items then
            for _, it in ipairs(v.items) do
                table.insert(rawItems, it)
            end
        else
            table.insert(rawItems, v)
        end
    end

    local meats = collectMeatSources(rawItems)
    if #meats == 0 then return end

    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    -- Require any sharp knife-like tool
    if not playerObj:getInventory():containsTag("SharpKnife") then return end

    context:addOption(
        getText("ContextMenu_KitchenConsolidation_Make_Meat_Pieces"),
        meats,
        function()
            ISTimedActionQueue.add(
                PrepareMeatAction:new(playerObj, meats)
            )
        end
    )
end

-- ---------------------------------------------------------------------------
-- Event Registration
-- ---------------------------------------------------------------------------

Events.OnFillInventoryObjectContextMenu.Add(addPrepareMeatOption)
