-- ZomboidEngine/ItemWeight.lua
-- Procedural runtime weight handling shim matching working Zomboid mod patterns
-- Weight is authoritative runtime state
-- Always write weight explicitly after spawn
-- Reads weight only via item:getWeight()
-- Writes weight only via item:setWeight(value)
-- Enables setCustomWeight if present, but does not depend on it

local Runtime = require("Runtime/Runtime")
local Log = Runtime.Logger
local Optional = Runtime.Optional


local ItemWeight = {}

function ItemWeight.get(item)
    if not item or type(item.getWeight) ~= "function" then
        Log.warn("ItemWeight.get: item does not support getWeight")
        return nil
    end
    local ok, weight = pcall(item.getWeight, item)
    if not ok or type(weight) ~= "number" then
        Log.warn("ItemWeight.get: failed to get weight")
        return nil
    end
    if math.abs(weight) < 1e-6 then
        return 0
    else
        return math.floor(weight * 1e6 + 0.5) / 1e6
    end
end

function ItemWeight.set(item, value)
    if type(value) ~= "number" or value <= 0 then
        Log.warn("ItemWeight.set: value must be a number greater than 0")
        return false
    end
    if not item or type(item.setWeight) ~= "function" then
        Log.warn("ItemWeight.set: item does not support setWeight")
        return false
    end

    local beforeWeight = nil
    do
        local ok, w = pcall(item.getWeight, item)
        if ok and type(w) == "number" then
            beforeWeight = w
        else
            beforeWeight = nil
        end
    end
    Log.info(string.format("ItemWeight.set: before weight = %s, intended weight = %s", tostring(beforeWeight), tostring(value)))

    if type(item.setCustomWeight) == "function" then
        local ok, _ = pcall(item.setCustomWeight, item, true)
        if not ok then
            Log.warn("ItemWeight.set: failed to call setCustomWeight")
        end
    end

    local okSet, _ = pcall(item.setWeight, item, value)
    if not okSet then
        Log.warn("ItemWeight.set: failed to set weight")
        return false
    end

    local afterWeight = nil
    do
        local ok, w = pcall(item.getWeight, item)
        if ok and type(w) == "number" then
            afterWeight = w
        else
            afterWeight = nil
        end
    end
    Log.info(string.format("ItemWeight.set: after weight = %s", tostring(afterWeight)))

    if type(afterWeight) == "number" then
        local epsilon = 0.0001
        if math.abs(afterWeight - value) > epsilon then
            Log.error(string.format(
                "ItemWeight.set: weight mismatch after set (outside tolerance): intended %s but got %s",
                tostring(value),
                tostring(afterWeight)
            ))
            return false
        end
    else
        Log.error("ItemWeight.set: weight readback failed after set")
        return false
    end

    return true
end

function ItemWeight.copy(targetItem, sourceItem)
    if not targetItem or not sourceItem then
        Log.warn("ItemWeight.copy: targetItem and sourceItem must be provided")
        return false
    end
    local weight = ItemWeight.get(sourceItem)
    if weight == nil then
        Log.warn("ItemWeight.copy: failed to read weight from sourceItem")
        return false
    end
    local ok = ItemWeight.set(targetItem, weight)
    return ok
end

return ItemWeight
