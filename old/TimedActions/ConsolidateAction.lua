-- ConsolidateAction.lua
-- Thin timed action: orchestration only, no domain logic

require "TimedActions/ISBaseTimedAction"

local Runtime = require("Runtime/Runtime")
local assured = Runtime.Guard.assured
local failOn = Runtime.Guard.failOn
local warnOn = Runtime.Guard.warnOn
local debug = Runtime.Logger.debug


local FoodInstance = require("Domain/FoodInstance")

ConsolidateAction = ISBaseTimedAction:derive("ConsolidateAction")

-- ---------------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------------

function ConsolidateAction:new(character, items)
    local o = ISBaseTimedAction.new(self, character)
    o.items = type(items) == "table" and items or {}
    o._instances = nil
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 30 + (#o.items * 10)
    return o
end

-- ---------------------------------------------------------------------------
-- Validation
-- ---------------------------------------------------------------------------

function ConsolidateAction:isValid()
    failOn(not self.character, "ConsolidateAction:isValid missing character")

    local inv = self.character:getInventory()
    failOn(not inv, "ConsolidateAction:isValid missing inventory")

    failOn(#self.items < 2, "ConsolidateAction:isValid fewer than 2 items")

    local instances = {}
    for _, item in ipairs(self.items) do
        failOn(not inv:contains(item), "ConsolidateAction:isValid inventory missing item")
        local inst = FoodInstance.fromItem(item)
        failOn(not inst, "ConsolidateAction:isValid: could not build FoodInstance from item")
        instances[#instances + 1] = inst
    end

    -- All instances must be combinable with each other (same type, not full)
    local first = instances[1]
    for i = 2, #instances do
        failOn(not (first:canCombineWith(instances[i])), "ConsolidateAction:isValid: items cannot be combined (type mismatch or full)")
    end

    self._instances = instances
    return true
end

-- ---------------------------------------------------------------------------
-- Timed action lifecycle
-- ---------------------------------------------------------------------------

function ConsolidateAction:start()
    self:setActionAnim("Loot")
    self.character:reportEvent("EventLootItem")
end

function ConsolidateAction:update()
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function ConsolidateAction:stop()
    ISBaseTimedAction.stop(self)
end

-- ---------------------------------------------------------------------------
-- Perform
-- ---------------------------------------------------------------------------

function ConsolidateAction:perform()
    local inv = self.character:getInventory()
    failOn(not inv, "ConsolidateAction:perform missing inventory")

    local instances = self._instances
    if not instances or #instances < 2 then
        -- Fallback safety: rebuild once if somehow missing
        warnOn(true, "ConsolidateAction:perform rebuilding FoodInstances (invariant violation: _instances missing or invalid)")
        instances = {}
        for _, item in ipairs(self.items) do
            local inst = FoodInstance.fromItem(item)
            failOn(not inst, "ConsolidateAction:perform failed to build FoodInstance")
            instances[#instances + 1] = inst
        end
        self._instances = instances
    end

    local result = FoodInstance.consolidate(instances)
    failOn(not result or not result.addToInventory,
           "ConsolidateAction:perform consolidate() did not return PrepResult")

    for _, item in ipairs(self.items) do
        if inv:contains(item) then
            inv:Remove(item)
        else
            warnOn(true, "ConsolidateAction:perform remove missing item")
        end
    end

    result:addToInventory(inv)

    ISBaseTimedAction.perform(self)
end

return ConsolidateAction
