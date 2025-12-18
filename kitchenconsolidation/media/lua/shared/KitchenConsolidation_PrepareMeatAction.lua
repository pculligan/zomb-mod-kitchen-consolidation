-- KitchenConsolidation_PrepareMeatAction.lua
-- Timed action for bulk preparation of meat fillets into MeatPieces
-- Phase 2: Preparation (discrete → fungible)

require "TimedActions/ISBaseTimedAction"

local Util = require("KitchenConsolidation_Util")
local Meats = require("KitchenConsolidation_Meats")

PrepareMeatAction = ISBaseTimedAction:derive("PrepareMeatAction")

-- ---------------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------------

function PrepareMeatAction:new(character, fillets)
    local o = ISBaseTimedAction.new(self, character)
    o.fillets = fillets or {}
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 20 + (#o.fillets * 10)
    return o
end

-- ---------------------------------------------------------------------------
-- Validation
-- ---------------------------------------------------------------------------

function PrepareMeatAction:isValid()
    if not self.character then return false end
    if not self.fillets or #self.fillets == 0 then return false end

    local inv = self.character:getInventory()
    if not inv then return false end

    -- Any sharp / knife-like tool is acceptable
    if not inv:containsTag("SharpKnife") then
        return false
    end

    -- All fillets must still be present
    for _, item in ipairs(self.fillets) do
        if not inv:contains(item) then
            return false
        end
    end

    return true
end

-- ---------------------------------------------------------------------------
-- Timed action lifecycle
-- ---------------------------------------------------------------------------

function PrepareMeatAction:start()
    self:setActionAnim("Loot")
    self.character:reportEvent("EventLootItem")
end

function PrepareMeatAction:update()
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function PrepareMeatAction:stop()
    ISBaseTimedAction.stop(self)
end

-- ---------------------------------------------------------------------------
-- Core preparation logic
-- ---------------------------------------------------------------------------

function PrepareMeatAction:perform()
    Util.debug("=== PrepareMeatAction:perform ===")
    local inv = self.character:getInventory()

    -- Defensive copy of sources, with de-duplication and whitelist filtering
    local seen = {}
    local sources = {}

    for _, item in ipairs(self.fillets) do
        if item
            and not seen[item]
            and Meats.SOURCES[item:getFullType()]
        then
            seen[item] = true
            table.insert(sources, item)
        end
    end
    Util.debug("Source meats:")
    for i, item in ipairs(sources) do
        Util.debug(string.format(
            "  src[%d] %s hunger=%s base=%s frac=%.3f",
            i,
            tostring(item:getFullType()),
            tostring(item:getHungChange()),
            tostring(item:getBaseHunger()),
            tonumber(Util.computeFraction(item)) or -1
        ))
    end

    if #sources == 0 then
        ISBaseTimedAction.perform(self)
        return
    end

    -- Aggregate remaining meat meat by absolute hunger (fillets and MeatPieces use different base units)
    local totalHunger = 0
    for _, item in ipairs(sources) do
        totalHunger = totalHunger + math.abs(item:getHungChange())
    end

    Util.debug("Total meat hunger to add: " .. tostring(totalHunger))

    -- Find any existing MeatPieces pile (do not branch on hidden state)
    local targetPile = nil
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it:getFullType() == "KitchenConsolidation.MeatPieces" then
            Util.debug("Found existing MeatPieces pile")
            targetPile = it
            break
        end
    end

    -- Remove all source meats (identity is discarded at preparation)
    -- Emit byproducts for containerized meats (e.g. canned ham → empty can)
    for _, item in ipairs(sources) do
        local fullType = item:getFullType()
        Util.debug("Removing meat source: " .. tostring(fullType))

        local byproduct = Meats.BYPRODUCT_ON_EMPTY and Meats.BYPRODUCT_ON_EMPTY[fullType]
        if byproduct then
            inv:AddItem(byproduct)
            Util.debug("Emitting byproduct: " .. tostring(byproduct))
        end

        inv:Remove(item)
    end

    -- Helper to add absolute hunger to a MeatPieces pile
    local function addHungerToPile(pile, hunger)
        Util.debug(string.format(
            "Adding to pile: adds %.3f hunger",
            hunger
        ))
        local current = math.abs(pile:getHungChange())
        local newTotal = current + hunger
        local newHung = -newTotal

        if pile.setHungChange then
            pile:setHungChange(newHung)
        elseif pile.setHungerChange then
            pile:setHungerChange(newHung)
        end
    end

    -- Ensure we have a target pile
    if not targetPile then
        Util.debug("No existing MeatPieces pile found; creating new pile")
        targetPile = inv:AddItem("KitchenConsolidation.MeatPieces")
    else
        Util.debug("Using existing MeatPieces pile")
    end

    Util.debug("MeatPieces base hunger before = " .. tostring(targetPile:getBaseHunger()))
    -- Add aggregated hunger directly to MeatPieces pile
    addHungerToPile(targetPile, totalHunger)

    Util.debug("MeatPieces base hunger after = " .. tostring(targetPile:getBaseHunger()))
    -- Apply worst-case freshness/sickness and capped weight AFTER aggregation
    Util.applyWorstCaseFreshness(sources, targetPile)
    Util.applyWorstCaseSickness(sources, targetPile)
    Util.applyCappedWeight(sources, targetPile)

    Util.debug(string.format(
        "Final MeatPieces pile: hunger=%s units=%.3f",
        tostring(targetPile:getHungChange()),
        math.abs(targetPile:getHungChange()) / math.abs(targetPile:getBaseHunger())
    ))
    Util.debug("=== PrepareMeatAction:perform END ===")
    ISBaseTimedAction.perform(self)
end


return PrepareMeatAction
