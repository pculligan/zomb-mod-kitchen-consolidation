-- PrepareAction.lua
--
-- Generic timed action for preparing discrete food items into prepared forms
-- (e.g., FishFillet -> FishPieces, Cabbage -> CabbagePieces).
--
-- Key rule:
--   Prepared items preserve source consumption semantics.
--   The only added behavior is combinability (handled elsewhere).
--
-- This action does NOT aggregate hunger or normalize nutrition.

local Runtime = require("infra/Runtime")
local assured = Runtime.Guard.assured
local failOn = Runtime.Guard.failOn
local warnOn = Runtime.Guard.warnOn
local debug = Runtime.Logger.debug

local Log = Runtime.Logger


local FoodInstance = require("core/domain/FoodInstance")

PrepareAction = ISBaseTimedAction:derive("PrepareAction")

function PrepareAction:new(player, sources, targetFullType)
    local o = ISBaseTimedAction.new(self, player)
    o.sources = sources
    o.targetFullType = targetFullType
    o._instances = nil
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 100
    return o
end

function PrepareAction:isValid()
    failOn(not self.sources or #self.sources == 0, "PrepareAction: no sources provided")
    assured(self.character, "PrepareAction: character missing")
    local inv = self.character:getInventory()
    assured(inv, "PrepareAction: no inventory found")

    local instances = {}
    for i, item in ipairs(self.sources) do
        failOn(not item, "PrepareAction: source item is nil")
        failOn(item:getContainer() ~= inv, "PrepareAction: source item not in inventory")

        local fi = FoodInstance.fromItem(item)
        failOn(not fi, "PrepareAction:isValid failed to build FoodInstance from source[" .. tostring(i) .. "]")
        -- Ensure it is eligible for this target
        failOn(not fi:canPrepTo(self.targetFullType), "PrepareAction:isValid: source[" .. tostring(i) .. "] not eligible for prepTo " .. tostring(self.targetFullType))
        table.insert(instances, fi)
    end

    self._instances = instances
    return true
end

function PrepareAction:start()
    self:setActionAnim("Loot")
    self:setOverrideHandModels(nil, nil)
end

function PrepareAction:perform()
    local inv = self.character and self.character:getInventory()
    assured(inv, "PrepareAction: inventory missing during perform")

    debug("PrepareAction:perform starting for target " .. tostring(self.targetFullType))

    local instances = self._instances
    if not instances or #instances == 0 then
        warnOn(true, "PrepareAction:perform rebuilding FoodInstances (invariant violation: _instances missing)")
        instances = {}
        for i, item in ipairs(self.sources) do
            local fi = FoodInstance.fromItem(item)
            failOn(not fi, "PrepareAction:perform failed to rebuild FoodInstance from source[" .. tostring(i) .. "]")
            table.insert(instances, fi)
        end
        self._instances = instances
    end

    -- Delegate prep to each FoodInstance (per-instance semantics)
    local results = {}
    for i, fi in ipairs(instances) do
        local result = fi:prepStep()
        if result then
            table.insert(results, result)
            debug("PrepareAction: source[" .. tostring(i) .. "] produced result")
        else
            debug("PrepareAction: source[" .. tostring(i) .. "] produced no result")
        end
    end

    failOn(#results == 0, "PrepareAction: prepStep produced no results; aborting")

    -- Remove source items from inventory
    for _, src in ipairs(self.sources) do
        if src and inv:contains(src) then
            inv:Remove(src)
        end
    end

    debug("PrepareAction: materializing " .. tostring(#results) .. " PrepResult(s)")
    for i, res in ipairs(results) do
        if warnOn(not (res and res.addToInventory), "PrepareAction: result[" .. tostring(i) .. "] missing addToInventory()") then
            -- warned, skip
        else
            res:addToInventory(inv)
        end
    end

    debug("PrepareAction:perform complete for " .. tostring(self.targetFullType))
    ISBaseTimedAction.perform(self)
end

return PrepareAction
