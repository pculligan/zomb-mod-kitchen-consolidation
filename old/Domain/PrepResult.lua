

local Runtime = require("Runtime/Runtime")
local assured = Runtime.Guard.assured
local failOn = Runtime.Guard.failOn
local warnOn = Runtime.Guard.warnOn
local debug = Runtime.Logger.debug

local Inventory = require("Engine/Engine").Inventory

-- PrepResult is the return type of FoodInstance:prepStep()
-- It represents the result of performing ONE prep step on ONE FoodInstance.
--
-- Fields:
--   produced   : { FoodInstance, ... }   -- 0..N outputs created by prep
--   byproducts : { string, ... }         -- item fullType strings (empties/jars/etc)
--
local PrepResult = {}
PrepResult.__index = PrepResult

function PrepResult.new(args)
    return setmetatable({
        produced   = args.produced   or {},
        byproducts = args.byproducts or {},
    }, PrepResult)
end

-- Materializes the results of a prep step into the given ItemContainer.
-- Handles produced FoodInstances and byproduct item fullType strings separately.
function PrepResult:addToInventory(container)
    debug("PrepResult.addToInventory ENTER")

    local function safeDump(v)
        if type(v) == "table" and v.debugDump == nil and getmetatable(v) and getmetatable(v).__index and getmetatable(v).__index.debugDump then
            -- Try to call debugDump if available
            local dbg = getmetatable(v).__index.debugDump
            if dbg then
                return dbg(v)
            end
        end
        if type(v) == "table" then
            return "<table>"
        end
        return tostring(v)
    end

    if not (container and container.AddItem) then
        return
    end

    -- First materialize produced FoodInstances
    for i, foodInst in ipairs(self.produced or {}) do
        if foodInst and foodInst.addToInventory then
            debug("PrepResult.addToInventory: materializing produced[" .. i .. "] " .. safeDump(foodInst))
            foodInst:addToInventory(container)
        else
            warnOn(true, "PrepResult.addToInventory: produced[" .. i .. "] is not a FoodInstance")
        end
    end

    -- Then materialize byproducts (strings only)
    for i, byp in ipairs(self.byproducts or {}) do
        if type(byp) == "string" then
            debug("PrepResult.addToInventory: adding byproduct item fullType=" .. byp)
            Inventory.add(container, byp)
        else
            warnOn(true, "PrepResult.addToInventory: invalid byproduct (expected string) at index " .. i)
        end
    end

    debug("PrepResult.addToInventory EXIT")
end

return PrepResult