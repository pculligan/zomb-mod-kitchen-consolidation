-- ZomboidEngine/Item.lua
-- Identity + validity shim only.
-- No mutation.

local Runtime = require("infra/Runtime")
local debug = Runtime.Logger.debug
local Optional = Runtime.Optional


local Item = {}

function Item.isValid(obj)
    return obj ~= nil
        and type(obj.getFullType) == "function"
end

-- Backward-compatible alias
Item.is = Item.isValid

function Item.raw(obj)
    if not Item.isValid(obj) then
        return Optional.none()
    end

    return Optional.some(obj)
end

function Item.fullType(obj)
    if not Item.isValid(obj) then
        return Optional.none()
    end

    local ok, ft = pcall(obj.getFullType, obj)
    if not ok or not ft then
        return Optional.none()
    end

    return Optional.some(ft)
end

function Item.id(obj)
    if not Item.isValid(obj) then
        return Optional.none()
    end

    if type(obj.getID) ~= "function" then
        return Optional.none()
    end

    local ok, id = pcall(obj.getID, obj)
    if not ok or id == nil then
        return Optional.none()
    end

    return Optional.some(id)
end

return Item
