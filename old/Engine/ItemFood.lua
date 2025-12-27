-- ZomboidEngine/ItemFood.lua
-- Thin, one-call shim for food-related engine mutations.
-- Mirrors patterns used by working mods (e.g. SapphCooking).
-- No math. No interpretation.

local ItemFood = {}

function ItemFood.setHunger(item, hunger, maxHunger)
    if type(hunger) ~= "number" or hunger >= 0 then
        return
    end

    item:setBaseHunger(hunger)
    item:setHungChange(hunger)
end

function ItemFood.setBoredom(item, value)
    item:setBoredomChange(value)
end

function ItemFood.setUnhappiness(item, value)
    item:setUnhappyChange(value)
end

function ItemFood.setPoisoned(item, poisoned)
    item:setPoisoned(poisoned)
end

function ItemFood.getHunger(item)
    if type(item.getHungChange) == "function" then
        return item:getHungChange()
    end
    if type(item.getHungerChange) == "function" then
        return item:getHungerChange()
    end
    return nil
end

function ItemFood.getBoredom(item)
    if type(item.getBoredomChange) == "function" then
        return item:getBoredomChange()
    end
    return nil
end

function ItemFood.getUnhappiness(item)
    if type(item.getUnhappyChange) == "function" then
        return item:getUnhappyChange()
    end
    if type(item.getUnhappinessChange) == "function" then
        return item:getUnhappinessChange()
    end
    return nil
end

function ItemFood.isPoisoned(item)
    if type(item.isPoisoned) == "function" then
        return item:isPoisoned()
    end
    return nil
end

function ItemFood.getPoisoned(item)
    return ItemFood.isPoisoned(item)
end

function ItemFood.getFoodSickness(item)
    if type(item.getFoodSickness) == "function" then
        return item:getFoodSickness()
    end
    return nil
end

function ItemFood.getFreshness(item)
    if type(item.isRotten) == "function" and item:isRotten() == true then
        return "rotten"
    end
    if type(item.isFresh) == "function" and item:isFresh() == true then
        return "fresh"
    end
    if type(item.isStale) == "function" and item:isStale() == true then
        return "stale"
    end
    return nil
end

function ItemFood.getCookState(item)
    if type(item.isBurnt) == "function" and item:isBurnt() == true then
        return "burnt"
    end
    if type(item.isCooked) == "function" and item:isCooked() == true then
        return "cooked"
    end
    if type(item.isCookable) == "function" and item:isCookable() == true then
        return "raw"
    end
    return nil
end

return ItemFood