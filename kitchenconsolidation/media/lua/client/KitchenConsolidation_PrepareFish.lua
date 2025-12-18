-- KitchenConsolidation_PrepareFish.lua
-- Client-side context menu action for bulk fish preparation
-- Inventory mutation is delegated to a timed action

local Util = require("KitchenConsolidation_Util")
require("KitchenConsolidation_PrepareFishAction")
-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function isFishFillet(item)
    if not instanceof(item, "Food") then return false end
    local ft = item:getFullType()
    return ft == "Base.FishFillet" or ft == "Base.SmallFishFillet"
end

local function collectFishFillets(items)
    local results = {}
    for _, item in ipairs(items) do
        if isFishFillet(item) then
            table.insert(results, item)
        end
    end
    return results
end

-- ---------------------------------------------------------------------------
-- Context Menu Hook
-- ---------------------------------------------------------------------------

local function addPrepareFishOption(player, context, worldobjects, test)
    if test then return true end    

    local rawItems = {}
    for _, v in ipairs(worldobjects) do
        if type(v) == "table" and v.items then
            for _, it in ipairs(v.items) do table.insert(rawItems, it) end
        else
            table.insert(rawItems, v)
        end
    end

    local fillets = collectFishFillets(rawItems)
    if #fillets == 0 then return end

    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    -- Require a knife for preparation
    if not playerObj:getInventory():containsType("KitchenKnife") then return end

    context:addOption(
        getText("ContextMenu_KitchenConsolidation_Make_Fish_Pieces"),
        fillets,
        function()
            ISTimedActionQueue.add(
                PrepareFishAction:new(playerObj, fillets)
            )
        end
    )
end

-- ---------------------------------------------------------------------------
-- Event Registration
-- ---------------------------------------------------------------------------

Events.OnFillInventoryObjectContextMenu.Add(addPrepareFishOption)
