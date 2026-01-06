-- -- Prepare.lua
-- -- Unified client-side context menu handler for all preparation actions
-- -- (fish, meat, vegetables, etc.)
-- --
-- -- This file:
-- --   * discovers eligible source items
-- --   * groups them by prepared target item
-- --   * exposes one context menu option per target
-- --   * dispatches a generic timed action
-- --
-- -- Inventory mutation is delegated to the timed action.


-- local Runtime = require("infra/Runtime")
-- local assured = Runtime.Guard.assured
-- local failOn = Runtime.Guard.failOn
-- local warnOn = Runtime.Guard.warnOn
-- local debug = Runtime.Logger.debug

-- local FoodRegistry = require("core/domain/FoodRegistry").instance
-- local FoodInstance = require("core/domain/FoodInstance")
-- require("TimedActions/PrepareAction")

-- -- ---------------------------------------------------------------------------
-- -- Helpers
-- -- ---------------------------------------------------------------------------

-- local function flattenWorldObjects(worldobjects)
--     local out = {}
--     for _, v in ipairs(worldobjects) do
--         if type(v) == "table" and v.items then
--             for _, it in ipairs(v.items) do
--                 table.insert(out, it)
--             end
--         else
--             table.insert(out, v)
--         end
--     end
--     return out
-- end

-- local function dedupeItems(items)
--     assured(type(items) == "table", "Prepare: dedupeItems expected table")
--     local seen = {}
--     local deduped = {}
--     for _, item in ipairs(items) do
--         local key = tostring(item)
--         if not seen[key] then
--             seen[key] = true
--             table.insert(deduped, item)
--         end
--     end
--     debug(string.format("Prepare: deduped items from %d to %d", #items, #deduped))
--     for i, item in ipairs(deduped) do
--         local fullType = item and item.getFullType and item:getFullType() or "<no getFullType>"
--         debug(string.format("Prepare: deduped[%d]: fullType=%s", i, fullType))
--     end
--     return deduped
-- end


-- -- ---------------------------------------------------------------------------
-- -- Context Menu Hook
-- -- ---------------------------------------------------------------------------

-- local function addPrepareOptions(player, context, worldobjects, test)
--     debug("Prepare: OnFillInventoryObjectContextMenu fired")

--     if failOn(test, "Prepare: test=true, returning early") then
--         return true
--     end

--     local items = flattenWorldObjects(worldobjects)
--     debug("Prepare: flattened items count = " .. tostring(#items))
--     items = dedupeItems(items)
--     debug("Prepare: using deduped items count = " .. tostring(#items))
--     for i, it in ipairs(items) do
--         local itType = it and it.getFullType and it:getFullType() or "<no getFullType>"
--         local itClass = tostring(it)
--         debug(string.format(
--             "Prepare: flattened[%d]: obj=%s fullType=%s",
--             i,
--             itClass,
--             itType
--         ))
--     end
--     if failOn(#items == 0, "Prepare: no items after flatten") then
--         return
--     end

--     local groups = FoodInstance.canPrepItems(items)
--     local groupCount = 0
--     for target, sources in pairs(groups) do
--         debug("Prepare: candidate target " .. tostring(target) .. " with " .. tostring(#sources) .. " sources")
--         groupCount = groupCount + 1
--     end

--     failOn(groupCount == 0, "Prepare: no prep-capable groups found")

--     local playerObj = getSpecificPlayer(player)
--     failOn(not playerObj, "Prepare: getSpecificPlayer returned nil")

--     local hasKnife = playerObj:getInventory():containsTag("SharpKnife")
--     debug("Prepare: has SharpKnife = " .. tostring(hasKnife))
--     if failOn(not hasKnife, "Prepare: missing SharpKnife") then return end

--     for target, sources in pairs(groups) do
--         if failOn(#sources == 0, "Prepare: empty sources for target "..tostring(target)) then
--             -- skip this target
--         else
--             local displayName

--             -- Resolve display name from target fullType
--             local scriptItem = getScriptManager():FindItem(target)
--             if warnOn(not scriptItem, "Prepare: script item not found for "..tostring(target)) then
--                 displayName = tostring(target)
--             else
--                 displayName = scriptItem:getDisplayName()
--             end

--             local label = getText("ContextMenu_KitchenConsolidation_Prepare", displayName)
--             debug("Prepare: adding menu option with label '" .. tostring(label) .. "'")

--             context:addOption(
--                 label,
--                 sources,
--                 function()
--                     debug("Prepare: dispatching PrepareAction for " .. tostring(target) .. " with " .. tostring(#sources) .. " sources")
--                     ISTimedActionQueue.add(
--                         PrepareAction:new(playerObj, sources, target)
--                     )
--                 end
--             )
--         end
--     end
-- end

-- -- ---------------------------------------------------------------------------
-- -- Event Registration
-- -- ---------------------------------------------------------------------------

-- Events.OnFillInventoryObjectContextMenu.Add(addPrepareOptions)