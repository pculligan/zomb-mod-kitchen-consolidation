-- KitchenConsolidation_Context.lua
-- Client-side context menu integration
-- No inventory mutation allowed in this file

local Util = require("KitchenConsolidation_Util")
local Action = require("KitchenConsolidation_Action")
local PrepareFishAction = require("KitchenConsolidation_PrepareFish")
local PrepareMeatAction = require("KitchenConsolidation_PrepareMeat")

require("KitchenConsolidation_Translations")

-- Verify translation table injection (Build 41)
if ContextMenu_EN then
    Util = Util or require("KitchenConsolidation_Util")
    Util.debug("ContextMenu_EN table exists")
    Util.debug("ContextMenu_KitchenConsolidation = " .. tostring(ContextMenu_EN["ContextMenu_KitchenConsolidation"]))
    Util.debug("ContextMenu_KitchenConsolidation_Type = " .. tostring(ContextMenu_EN["ContextMenu_KitchenConsolidation_Type"]))
    Util.debug("ContextMenu_KitchenConsolidation_All = " .. tostring(ContextMenu_EN["ContextMenu_KitchenConsolidation_All"]))
else
    Util = Util or require("KitchenConsolidation_Util")
    Util.debug("ERROR: ContextMenu_EN table does NOT exist")
end



-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function unwrapInventoryItems(items)
    local results = {}
    for _, v in ipairs(items) do
        if type(v) == "table" and v.items then
            for _, item in ipairs(v.items) do
                table.insert(results, item)
            end
        else
            table.insert(results, v)
        end
    end
    return results
end

local function getEligibleItems(items)
    local eligible = {}
    for _, item in ipairs(items) do
        if Util.isEligibleFoodItem(item) then
            table.insert(eligible, item)
        end
    end
    return eligible
end

-- ---------------------------------------------------------------------------
-- Context Menu Builder
-- ---------------------------------------------------------------------------

local function addCombineOptions(player, context, worldobjects, test)
    if test then return true end

    Util.debug("Context menu invoked")
    local lang = "unknown"

    -- Safely resolve language without calling methods in conditionals
    if type(getLanguage) == "function" then
        lang = getLanguage()
    else
        local core = (type(getCore) == "function") and getCore() or nil
        if core and type(core.getLanguage) == "function" then
            lang = core:getLanguage()
        end
    end

    Util.debug("Active game language = " .. tostring(lang))

    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local rawItems = unwrapInventoryItems(worldobjects)
    local eligible = getEligibleItems(rawItems)
    Util.debug("Eligible items count: " .. tostring(#eligible))

    if #eligible < 2 then return end

    -- Group eligible items using authoritative util logic
    local groups = Util.buildMergeGroups(eligible)
    local groupCount = 0

    for _, items in pairs(groups) do
        if #items > 1 then
            groupCount = groupCount + 1
        end
    end

    if groupCount == 0 then return end

    -- Per-group options (top-level)
    for _, items in pairs(groups) do
        if #items > 1 then
            local item = items[1]
            local label = getText("ContextMenu_KitchenConsolidation_Type", item:getDisplayName())
            Util.debug("Group label resolved to: " .. tostring(label))

            context:addOption(label, items, function()
                ISTimedActionQueue.add(
                    Action:new(playerObj, items)
                )
            end)
        end
    end

    -- Combine All option (only if multiple groups)
    if groupCount > 1 then
        context:addSeparator()
        local allLabel = getText("ContextMenu_KitchenConsolidation_All")
        Util.debug("Combine All label resolved to: " .. tostring(allLabel))
        context:addOption(allLabel, eligible, function()
            for _, items in pairs(groups) do
                if #items > 1 then
                    ISTimedActionQueue.add(
                        Action:new(playerObj, items)
                    )
                end
            end
        end)
    end
end

-- ---------------------------------------------------------------------------
-- Event Registration
-- ---------------------------------------------------------------------------

Events.OnFillInventoryObjectContextMenu.Add(addCombineOptions)
