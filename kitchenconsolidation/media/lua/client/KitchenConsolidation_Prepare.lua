-- KitchenConsolidation_Prepare.lua
-- Unified client-side context menu handler for all preparation actions
-- (fish, meat, vegetables, etc.)
--
-- This file:
--   * discovers eligible source items
--   * groups them by prepared target item
--   * exposes one context menu option per target
--   * dispatches a generic timed action
--
-- Inventory mutation is delegated to the timed action.

local Util = require("KitchenConsolidation_Util")
local PrepMap = require("KitchenConsolidation_PrepMap")
require("TimedActions/KitchenConsolidation_PrepareAction")

Util.debug("Prepare.lua loaded")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function flattenWorldObjects(worldobjects)
    local out = {}
    for _, v in ipairs(worldobjects) do
        if type(v) == "table" and v.items then
            for _, it in ipairs(v.items) do
                table.insert(out, it)
            end
        else
            table.insert(out, v)
        end
    end
    return out
end

local function collectPrepCandidates(items)
    local groups = {}
    for _, item in ipairs(items) do
        if instanceof(item, "Food") then
            local target = PrepMap[item:getFullType()]
            if target then
                groups[target] = groups[target] or {}
                table.insert(groups[target], item)
            end
        end
    end
    return groups
end

-- ---------------------------------------------------------------------------
-- Context Menu Hook
-- ---------------------------------------------------------------------------

local function addPrepareOptions(player, context, worldobjects, test)
    Util.debug("Prepare: OnFillInventoryObjectContextMenu fired")

    if test then
        Util.debug("Prepare: test=true, returning early")
        return true
    end

    local items = flattenWorldObjects(worldobjects)
    Util.debug("Prepare: flattened items = " .. tostring(#items))
    if #items == 0 then
        Util.debug("Prepare: no items after flatten; returning")
        return
    end

    local groups = collectPrepCandidates(items)
    local groupCount = 0
    for target, sources in pairs(groups) do
        Util.debug("Prepare: candidate target " .. tostring(target) .. " with " .. tostring(#sources) .. " sources")
        groupCount = groupCount + 1
    end

    if groupCount == 0 then
        Util.debug("Prepare: no PrepMap matches found; returning")
        return
    end

    local playerObj = getSpecificPlayer(player)
    if not playerObj then
        Util.debug("Prepare: getSpecificPlayer returned nil")
        return
    end

    local hasKnife = playerObj:getInventory():containsTag("SharpKnife")
    Util.debug("Prepare: has SharpKnife = " .. tostring(hasKnife))
    if not hasKnife then
        Util.debug("Prepare: missing SharpKnife; returning")
        return
    end

    for target, sources in pairs(groups) do
        if #sources > 0 then
            local labelKey = "ContextMenu_KitchenConsolidation_Make_" .. target:gsub("KitchenConsolidation%.", "")
            local label = getText(labelKey)
            Util.debug("Prepare: adding menu option " .. tostring(labelKey) .. " ('" .. tostring(label) .. "')")

            context:addOption(
                label,
                sources,
                function()
                    Util.debug("Prepare: dispatching PrepareAction for " .. tostring(target) .. " with " .. tostring(#sources) .. " sources")
                    ISTimedActionQueue.add(
                        PrepareAction:new(playerObj, sources, target)
                    )
                end
            )
        end
    end
end

-- ---------------------------------------------------------------------------
-- Event Registration
-- ---------------------------------------------------------------------------

Events.OnFillInventoryObjectContextMenu.Add(addPrepareOptions)