-- KitchenConsolidation_Consolidate.lua
-- Client-side context menu integration
-- No inventory mutation allowed in this file

local Util = require("KitchenConsolidation_Util")
local ConsolidateAction = require("TimedActions/KitchenConsolidation_ConsolidateAction")
if not (ConsolidateAction and ConsolidateAction.new) then
    Util.warn("Consolidate.lua: ConsolidateAction:new is missing (require returned " .. tostring(ConsolidateAction) .. ")")
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
    Util.debug("Consolidate: OnFillInventoryObjectContextMenu fired")

    if test then
        Util.debug("Consolidate: test=true, returning early")
        return true
    end

    local playerObj = getSpecificPlayer(player)
    if not playerObj then
        Util.debug("Consolidate: getSpecificPlayer returned nil")
        return
    end

    local rawItems = unwrapInventoryItems(worldobjects)
    Util.debug("Consolidate: flattened items = " .. tostring(#rawItems))

    local eligible = getEligibleItems(rawItems)
    Util.debug("Consolidate: eligible items = " .. tostring(#eligible))
    if #eligible < 2 then
        Util.debug("Consolidate: fewer than 2 eligible items; returning")
        return
    end

    local groups = Util.buildMergeGroups(eligible)
    local groupCount = 0
    for key, items in pairs(groups) do
        Util.debug("Consolidate: group " .. tostring(key) .. " has " .. tostring(#items) .. " items")
        if #items > 1 then
            groupCount = groupCount + 1
        end
    end

    if groupCount == 0 then
        Util.debug("Consolidate: no groups with more than one item; returning")
        return
    end

    for _, items in pairs(groups) do
        if #items > 1 then
            local item = items[1]
            local label = getText("ContextMenu_KitchenConsolidation_Type", item:getDisplayName())
            Util.debug("Consolidate: adding menu option '" .. tostring(label) .. "'")

            context:addOption(label, items, function()
                Util.debug("Consolidate: dispatching ConsolidateAction for " .. tostring(#items) .. " items")
                ISTimedActionQueue.add(
                    ConsolidateAction:new(playerObj, items)
                )
            end)
        end
    end

    if groupCount > 1 then
        context:addSeparator()
        local allLabel = getText("ContextMenu_KitchenConsolidation_All")
        Util.debug("Consolidate: adding Combine All option '" .. tostring(allLabel) .. "'")

        context:addOption(allLabel, eligible, function()
            for _, items in pairs(groups) do
                if #items > 1 then
                    Util.debug("Consolidate: dispatching ConsolidateAction (all) for " .. tostring(#items) .. " items")
                    ISTimedActionQueue.add(
                        ConsolidateAction:new(playerObj, items)
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
