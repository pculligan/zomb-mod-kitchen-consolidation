-- -- Consolidate.lua
-- -- Client-side context menu integration
-- -- No inventory mutation allowed in this file


-- local Runtime = require("Runtime/Runtime")
-- local assured = Runtime.Guard.assured
-- local failOn = Runtime.Guard.failOn
-- local warnOn = Runtime.Guard.warnOn
-- local debug = Runtime.Logger.debug


-- local ConsolidateAction = require("TimedActions/ConsolidateAction")
-- local FoodInstance = require("Domain/FoodInstance")

-- if failOn(not (FoodInstance and FoodInstance.fromItem),
--     "Consolidate.lua: FoodInstance module is missing or invalid; consolidation disabled for this session") then
--     return
-- end
-- local FoodRegistry = require("Domain/FoodRegistry")
-- local Registry = FoodRegistry.instance
-- warnOn(not (ConsolidateAction and ConsolidateAction.new),
--     "Consolidate.lua: ConsolidateAction:new is missing (require returned " .. tostring(ConsolidateAction) .. ")")

-- -- ---------------------------------------------------------------------------
-- -- Helpers
-- -- ---------------------------------------------------------------------------

-- local function unwrapInventoryItems(items)
--     local results = {}
--     for _, v in ipairs(items) do
--         if type(v) == "table" and v.items then
--             for _, item in ipairs(v.items) do
--                 table.insert(results, item)
--             end
--         else
--             table.insert(results, v)
--         end
--     end
--     return results
-- end

-- local function dedupeItems(items)
--     local seen = {}
--     local result = {}
--     for _, item in ipairs(items) do
--         if item and not seen[item] then
--             seen[item] = true
--             table.insert(result, item)
--         end
--     end
--     return result
-- end

-- local function logItemList(prefix, items)
--     debug(prefix .. " count=" .. tostring(#items))
--     for i, it in ipairs(items) do
--         local ft = it and it.getFullType and it:getFullType() or "nil"
--         debug(prefix .. "[" .. i .. "] obj=" .. tostring(it) .. " fullType=" .. tostring(ft))
--     end
-- end

-- -- ---------------------------------------------------------------------------
-- -- Context Menu Builder
-- -- ---------------------------------------------------------------------------

-- local function addCombineOptions(player, context, worldobjects, test)
--     debug("Consolidate: OnFillInventoryObjectContextMenu fired")

--     if failOn(test, "Consolidate: test=true, returning early") then
--         return true
--     end

--     local playerObj = getSpecificPlayer(player)
--     if failOn(not playerObj, "Consolidate: getSpecificPlayer returned nil") then
--         return
--     end

--     local items = dedupeItems(unwrapInventoryItems(worldobjects))
--     logItemList("Consolidate: items", items)
--     debug("Consolidate: flattened items = " .. tostring(#items))

--     local instancesByKey = {}
--     local itemsByKey = {}
--     local totalInstances = 0
--     for _, item in ipairs(items) do
--         if item and item.getFullType then
--             debug("Consolidate: inspecting raw item " .. tostring(item) ..
--                 " type=" .. tostring(item:getFullType()))
--             local fullType = item:getFullType()
--             if not fullType then
--                 warnOn(true, "Consolidate: item.getFullType returned nil, skipping")
--             elseif not Registry then
--                 warnOn(true, "Consolidate: FoodRegistry.instance missing; skipping item " .. tostring(fullType))
--             elseif not Registry:has(fullType) then
--                 warnOn(true, "Consolidate: fullType not in FoodRegistry, skipping " .. tostring(fullType))
--             else
--                 local inst = FoodInstance.fromItem(item)
--                 if inst then
--                     local ft = inst.type
--                     -- Consolidation policy: only containerized items that are NOT full
--                     if not (ft and ft.isContainerized) then
--                         debug("Consolidate: skipping non-containerized item " .. tostring(ft and ft.fullType or "<nil>"))
--                     elseif inst:isFull() then
--                         debug("Consolidate: skipping FULL item " .. tostring(ft and ft.fullType or "<nil>"))
--                     else
--                         -- Use fullType as consolidation key (domain-level, not engine-level)
--                         local key = ft and ft.fullType
--                         if key then
--                             instancesByKey[key] = instancesByKey[key] or {}
--                             table.insert(instancesByKey[key], inst)
--                             itemsByKey[key] = itemsByKey[key] or {}
--                             table.insert(itemsByKey[key], item)
--                             totalInstances = totalInstances + 1
--                         else
--                             debug("Consolidate: skipping item with missing consolidationKey " .. tostring(ft and ft.fullType or "<nil>"))
--                         end
--                     end
--                 end
--             end
--         else
--             if not item then
--                 warnOn(true, "Consolidate: encountered nil item in rawItems, skipping")
--             else
--                 warnOn(true, "Consolidate: item missing getFullType method, skipping")
--             end
--         end
--     end

--     local keysCount = 0
--     for _ in pairs(instancesByKey) do
--         keysCount = keysCount + 1
--     end
--     debug("Consolidate: instancesByKey has " .. tostring(keysCount) .. " keys")
--     for key, instances in pairs(instancesByKey) do
--         debug("Consolidate: key '" .. tostring(key) .. "' has " .. tostring(#instances) .. " instances")
--     end

--     debug("Consolidate: eligible instances = " .. tostring(totalInstances))
--     if not assured(totalInstances > 1, "Consolidate: fewer than 2 eligible instances; returning") then
--         return
--     end

--     local groupCount = 0
--     for key, instances in pairs(instancesByKey) do
--         debug("Consolidate: group " .. tostring(key) .. " has " .. tostring(#instances) .. " instances")
--         if #instances > 1 then
--             groupCount = groupCount + 1
--         end
--     end

--     if failOn(groupCount == 0, "Consolidate: no groups with more than one instance; returning") then
--         return
--     end

--     for key, instances in pairs(instancesByKey) do
--         if #instances > 1 then
--             local firstInst = instances[1]
--             local items = itemsByKey[key] or {}
--             local item = items[1]
--             local displayName = (item and item.getDisplayName and item:getDisplayName()) or tostring(firstInst.type.fullType)
--             local label = getText("ContextMenu_KitchenConsolidation_Consolidate") .. " (" .. displayName .. ")"
--             debug("Consolidate: adding menu option '" .. tostring(label) .. "'")

--             if #items < 2 then
--                 debug("Consolidate: skipping menu option for label '" .. tostring(label) .. "' because fewer than 2 items remain")
--             else
--                 context:addOption(label, items, function()
--                     debug("Consolidate: dispatching ConsolidateAction for " .. tostring(#items) .. " items")
--                     ISTimedActionQueue.add(
--                         ConsolidateAction:new(playerObj, items)
--                     )
--                 end)
--             end
--         end
--     end

--     if groupCount > 1 then
--         context:addSeparator()
--         local allLabel = getText("ContextMenu_KitchenConsolidation_ConsolidateAll")
--         debug("Consolidate: adding Combine All option '" .. tostring(allLabel) .. "'")

--         local allItems = {}
--         for key, instances in pairs(instancesByKey) do
--             if #instances > 1 then
--                 local items = itemsByKey[key] or {}
--                 for _, raw in ipairs(items) do
--                     table.insert(allItems, raw)
--                 end
--             end
--         end
--         debug("Consolidate: Combine All items count=" .. tostring(#allItems))
--         if #allItems < 2 then
--             debug("Consolidate: skipping Combine All option because fewer than 2 items exist")
--         else
--             context:addOption(allLabel, allItems, function()
--                 -- For each group, dispatch if there are at least 2 items
--                 for key, instances in pairs(instancesByKey) do
--                     if #instances > 1 then
--                         local items = itemsByKey[key] or {}
--                         debug("Consolidate: (Combine All) group items count=" .. tostring(#items))
--                         if #items >= 2 then
--                             debug("Consolidate: dispatching ConsolidateAction (all) for " .. tostring(#items) .. " items")
--                             ISTimedActionQueue.add(
--                                 ConsolidateAction:new(playerObj, items)
--                             )
--                         else
--                             debug("Consolidate: skipping (Combine All) group because fewer than 2 items exist")
--                         end
--                     end
--                 end
--             end)
--         end
--     end
-- end

-- -- ---------------------------------------------------------------------------
-- -- Event Registration
-- -- ---------------------------------------------------------------------------

-- Events.OnFillInventoryObjectContextMenu.Add(addCombineOptions)
