-- ZomboidEngine/Inventory.lua
-- Procedural inventory helpers
-- No abstraction, no state


local Runtime = require("infra/Runtime")
local debug = Runtime.Logger.debug
local Optional = Runtime.Optional

local Inventory = {}

function Inventory.is(inv)
    if inv == nil then
        return false
    end
    if type(inv.AddItem) == "function" then
        return true
    end
    if type(inv.addItem) == "function" then
        return true
    end
    return false
end

function Inventory.add(inv, item)
    if inv == nil or item == nil then
        return nil
    end

    if type(inv.AddItem) == "function" then
        local ok, result = pcall(inv.AddItem, inv, item)
        if ok then
            return item
        end
    end

    if type(inv.addItem) == "function" then
        local ok, result = pcall(inv.addItem, inv, item)
        if ok then
            return item
        end
    end

    return nil
end

function Inventory.remove(inv, item)
    if inv == nil or item == nil then
        return false
    end

    if type(inv.Remove) == "function" then
        local ok, _ = pcall(inv.Remove, inv, item)
        if ok then
            return true
        end
    end

    if type(inv.RemoveItem) == "function" then
        local ok, _ = pcall(inv.RemoveItem, inv, item)
        if ok then
            return true
        end
    end

    return false
end

function Inventory.contains(inv, item)
    if inv == nil or item == nil then
        return false
    end
    if type(inv.getItems) ~= "function" then
        return false
    end

    local ok, items = pcall(inv.getItems, inv)
    if not ok or type(items) ~= "table" then
        return false
    end

    if type(items.size) ~= "function" or type(items.get) ~= "function" then
        return false
    end

    local okSize, size = pcall(items.size, items)
    if not okSize or type(size) ~= "number" then
        return false
    end

    for i = 0, size - 1 do
        local okGet, it = pcall(items.get, items, i)
        if okGet and it == item then
            return true
        end
    end

    return false
end

function Inventory.size(inv)
    if type(inv) ~= "table" then
        return Optional.none()
    end
    if type(inv.getItems) ~= "function" then
        return Optional.none()
    end

    local ok, items = pcall(inv.getItems, inv)
    if not ok or type(items) ~= "table" then
        debug("Inventory.size: failed to get items list")
        return Optional.none()
    end

    if type(items.size) ~= "function" then
        return Optional.none()
    end

    local ok2, sz = pcall(items.size, items)
    if not ok2 or type(sz) ~= "number" then
        debug("Inventory.size: failed to get size")
        return Optional.none()
    end

    return Optional.some(sz)
end

return Inventory