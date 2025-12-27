local Runtime = require("Runtime/Runtime")

local debug = Runtime.Logger.debug
local trace = Runtime.Logger.trace







require "RecipeContainerized"
require "recipecode"

do
    local sm = getScriptManager()
    if sm and sm.getAllEvolvedRecipes then
        local list = sm:getAllEvolvedRecipes()
        if list and list.size then
            for i = 0, list:size() - 1 do
                local r = list:get(i)
                if r and r.getResultItem and not r:getResultItem() then
                    print("[KitchenConsolidation] EVOLVED RECIPE WITH NIL RESULT (early):", r:getName())
                end
            end
        end
    else
        print("[KitchenConsolidation] ScriptManager or evolved recipes not available yet")
    end
end






-- ------------------------------------------------------------------
-- Safe item lookup helper (prevents nil ScriptItem crashes)
-- ------------------------------------------------------------------
local KC_COMBINE_TRACE = true

local function KC_AddItem(scriptItems, fullType)
    local it = getScriptManager():FindItem(fullType)
    if it then
        scriptItems:add(it)
    else
        print("[KitchenConsolidation] MISSING ITEM:", fullType)
    end
end

function Recipe.GetItemTypes.KitchenConsolidation_Pieces(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("KitchenConsolidation.Pieces"));
end

function Recipe.GetItemTypes.KitchenConsolidation_FishPiecesSources(scriptItems)
    KC_AddItem(scriptItems, "Base.FishFillet")
end

function Recipe.GetItemTypes.KitchenConsolidation_MeatPiecesSources(scriptItems)
    -- From Vanilla
    KC_AddItem(scriptItems, "farming.Bacon")
    KC_AddItem(scriptItems, "farming.BaconRashers")
    KC_AddItem(scriptItems, "Base.Baloney")
    KC_AddItem(scriptItems, "Base.BaloneySlice")
    -- KC_AddItem(scriptItems, "Base.Beef")
    KC_AddItem(scriptItems, "Base.BeefJerky")
    KC_AddItem(scriptItems, "Base.MeatPatty")
    -- KC_AddItem(scriptItems, "Base.ChickenWhole")
    -- KC_AddItem(scriptItems, "Base.ChickenFillet")
    KC_AddItem(scriptItems, "Base.Chicken")
    -- KC_AddItem(scriptItems, "Base.ChickenNuggets")
    -- KC_AddItem(scriptItems, "Base.ChickenWings")
    KC_AddItem(scriptItems, "Base.MincedMeat")
    KC_AddItem(scriptItems, "Base.Ham")
    KC_AddItem(scriptItems, "Base.HamSlice")
    -- KC_AddItem(scriptItems, "Base.Hotdog_single")
    -- KC_AddItem(scriptItems, "Base.MuttonChop")
    -- KC_AddItem(scriptItems, "Base.HotdogPack")
    KC_AddItem(scriptItems, "Base.Pepperoni")
    -- KC_AddItem(scriptItems, "Base.Pork")
    KC_AddItem(scriptItems, "Base.PorkChop")
    KC_AddItem(scriptItems, "Base.Salami")
    KC_AddItem(scriptItems, "Base.SalamiSlice")
    KC_AddItem(scriptItems, "Base.Sausage")
    KC_AddItem(scriptItems, "Base.Steak")
    -- KC_AddItem(scriptItems, "Base.TurkeyWhole")
    -- KC_AddItem(scriptItems, "Base.TurkeyFillet")
    -- KC_AddItem(scriptItems, "Base.TurkeyLegs")
    -- KC_AddItem(scriptItems, "Base.TurkeyWings")
    -- KC_AddItem(scriptItems, "Base.Venison")
    KC_AddItem(scriptItems, "Base.Rabbitmeat")
    KC_AddItem(scriptItems, "Base.Smallbirdmeat")
    KC_AddItem(scriptItems, "Base.Smallanimalmeat")
    KC_AddItem(scriptItems, "Base.FrogMeat")
    -- From FoodPreservationPlus 
    -- KC_AddItem(scriptItems, "Base.Rabbitmeat")
    KC_AddItem(scriptItems, "Base.SalamiHomemade")
    KC_AddItem(scriptItems, "Base.SaltedMeat")
    KC_AddItem(scriptItems, "Base.SmokedMeat")
    -- From CookingTime 
    KC_AddItem(scriptItems, "filcher.Calabrese")
    KC_AddItem(scriptItems, "filcher.CannedHamOpen")
    KC_AddItem(scriptItems, "filcher.SFPorkribs")
    KC_AddItem(scriptItems, "filcher.SFSausage")
    KC_AddItem(scriptItems, "filcher.Smallbirdmeat")
    KC_AddItem(scriptItems, "filcher.SmokedMeat")
end


function Recipe.GetItemTypes.KitchenConsolidation_ContainerizedCan(scriptItems)
    -- Tin can byproducts

    -- Vanilla
    KC_AddItem(scriptItems, "Base.OpenBeans")
    KC_AddItem(scriptItems, "Base.CannedCarrotsOpen")
    KC_AddItem(scriptItems, "Base.CannedChiliOpen")
    KC_AddItem(scriptItems, "Base.CannedCornOpen")
    KC_AddItem(scriptItems, "Base.CannedCornedBeefOpen")
    KC_AddItem(scriptItems, "Base.DogfoodOpen")
    KC_AddItem(scriptItems, "Base.CannedMilkOpen")
    KC_AddItem(scriptItems, "Base.CannedFruitBeverageOpen")
    KC_AddItem(scriptItems, "Base.CannedFruitCocktailOpen")
    KC_AddItem(scriptItems, "Base.CannedMushroomSoupOpen")
    KC_AddItem(scriptItems, "Base.CannedPeachesOpen")
    KC_AddItem(scriptItems, "Base.CannedPeasOpen")
    KC_AddItem(scriptItems, "Base.CannedPineappleOpen")
    KC_AddItem(scriptItems, "Base.CannedPotatoOpen")
    KC_AddItem(scriptItems, "Base.CannedSardinesOpen")
    KC_AddItem(scriptItems, "Base.CannedBologneseOpen")
    KC_AddItem(scriptItems, "Base.CannedTomatoOpen")
    KC_AddItem(scriptItems, "Base.TunaTinOpen")
    KC_AddItem(scriptItems, "Base.TinnedSoupOpen")

    -- CookingTime
    KC_AddItem(scriptItems, "filcher.CannedHamOpen")
    KC_AddItem(scriptItems, "filcher.CannedSoupOpen")
    KC_AddItem(scriptItems, "filcher.OpenCannedSpagetti")
    KC_AddItem(scriptItems, "filcher.OpenCannedSpinach")
    KC_AddItem(scriptItems, "filcher.SFCatfoodOpen")
end

function Recipe.GetItemTypes.KitchenConsolidation_ContainerizedJar(scriptItems)
    -- Jar byproducts

    -- Vanilla
    KC_AddItem(scriptItems, "Base.CannedBellPepper_Open")
    KC_AddItem(scriptItems, "Base.CannedBroccoli_Open")
    KC_AddItem(scriptItems, "Base.CannedCabbage_Open")
    KC_AddItem(scriptItems, "Base.CannedCarrots_Open")
    KC_AddItem(scriptItems, "Base.CannedEggplant_Open")
    KC_AddItem(scriptItems, "Base.CannedLeek_Open")
    KC_AddItem(scriptItems, "Base.CannedPotato_Open")
    KC_AddItem(scriptItems, "Base.CannedRedRadish_Open")
    KC_AddItem(scriptItems, "Base.CannedTomato_Open")
    KC_AddItem(scriptItems, "Base.CannedRoe_Open")

    -- CookingTime
    KC_AddItem(scriptItems, "filcher.SFChocolateWaferSticksJarOpen")
    KC_AddItem(scriptItems, "filcher.SFPickles")
    KC_AddItem(scriptItems, "filcher.SFJelly")
    KC_AddItem(scriptItems, "filcher.SFTomatoSauce")
end

function Recipe.GetItemTypes.KitchenConsolidation_ContainerizedBottle(scriptItems)
    -- Bottle byproducts

    KC_AddItem(scriptItems, "Base.OilOlive")
    KC_AddItem(scriptItems, "Base.OilVegetable")
    KC_AddItem(scriptItems, "Base.SesameOil")
    KC_AddItem(scriptItems, "Base.Vinegar")
    KC_AddItem(scriptItems, "Base.RiceVinegar")
end

function Recipe.GetItemTypes.KitchenConsolidation_ContainerizedNone(scriptItems)
    -- Containerized foods with no returned container

    -- Vanilla
    KC_AddItem(scriptItems, "Base.Flour2")
    KC_AddItem(scriptItems, "Base.Cornmeal2")
    KC_AddItem(scriptItems, "Base.Cornflour2")
    KC_AddItem(scriptItems, "Base.Blackbeans")
    KC_AddItem(scriptItems, "Base.DriedBlackBeans")
    KC_AddItem(scriptItems, "Base.DriedChickpeas")
    KC_AddItem(scriptItems, "Base.DriedKidneyBeans")
    KC_AddItem(scriptItems, "Base.DriedLentils")
    KC_AddItem(scriptItems, "Base.DriedSplitPeas")
    KC_AddItem(scriptItems, "Base.DriedWhiteBeans")
    KC_AddItem(scriptItems, "Base.SoybeansSeed")
    KC_AddItem(scriptItems, "Base.Soybeans")
    KC_AddItem(scriptItems, "Base.Salt")
    KC_AddItem(scriptItems, "Base.SeasoningSalt")
    KC_AddItem(scriptItems, "Base.Sugar")
    KC_AddItem(scriptItems, "Base.SugarBrown")
    KC_AddItem(scriptItems, "Base.SugarPacket")
    KC_AddItem(scriptItems, "Base.SugarCubes")
    KC_AddItem(scriptItems, "Base.Honey")
    KC_AddItem(scriptItems, "Base.MapleSyrup")
    KC_AddItem(scriptItems, "Base.PowderedGarlic")
    KC_AddItem(scriptItems, "Base.PowderedOnion")
    KC_AddItem(scriptItems, "Base.Pepper")
    KC_AddItem(scriptItems, "Base.CornFrozen")
    KC_AddItem(scriptItems, "Base.Peas")
    KC_AddItem(scriptItems, "Base.MixedVegetables")
    KC_AddItem(scriptItems, "Base.Seasoning_Basil")
    KC_AddItem(scriptItems, "Base.Seasoning_Chives")
    KC_AddItem(scriptItems, "Base.Seasoning_Cilantro")
    KC_AddItem(scriptItems, "Base.Seasoning_Oregano")
    KC_AddItem(scriptItems, "Base.Seasoning_Parsley")
    KC_AddItem(scriptItems, "Base.Seasoning_Rosemary")
    KC_AddItem(scriptItems, "Base.Seasoning_Sage")
    KC_AddItem(scriptItems, "Base.Seasoning_Thyme")
    KC_AddItem(scriptItems, "Base.OatsRaw")
    KC_AddItem(scriptItems, "Base.Cereal")
    KC_AddItem(scriptItems, "Base.CocoaPowder")
    KC_AddItem(scriptItems, "Base.Coffee2")
    KC_AddItem(scriptItems, "Base.JamFruit")
    KC_AddItem(scriptItems, "Base.PeanutButter")
    KC_AddItem(scriptItems, "Base.TortillaChips")
    KC_AddItem(scriptItems, "Base.Crisps")
    KC_AddItem(scriptItems, "Base.Crisps2")
    KC_AddItem(scriptItems, "Base.Crisps3")
    KC_AddItem(scriptItems, "Base.Crisps4")
    KC_AddItem(scriptItems, "Base.CatFoodBag")
    KC_AddItem(scriptItems, "Base.DogFoodBag")
    KC_AddItem(scriptItems, "Base.Ramen")
    KC_AddItem(scriptItems, "Base.Macaroni")
    KC_AddItem(scriptItems, "Base.Pasta")
    KC_AddItem(scriptItems, "Base.Rice")
    KC_AddItem(scriptItems, "Base.TomatoPaste")

    -- CookingTime
    KC_AddItem(scriptItems, "filcher.Macaroni")
    --KC_AddItem(scriptItems, "filcher.SFPotatoSliced")
    KC_AddItem(scriptItems, "filcher.SFBeans")
    KC_AddItem(scriptItems, "filcher.BreadPieces")
    KC_AddItem(scriptItems, "filcher.SFHazelnutCream")
    KC_AddItem(scriptItems, "filcher.Cinnamon")
    KC_AddItem(scriptItems, "filcher.SFPaprika")
    KC_AddItem(scriptItems, "filcher.SFCurry")
end

-- ------------------------------------------------------------------
-- Container byproduct resolution (CSV-driven)
-- ------------------------------------------------------------------
KitchenConsolidation = KitchenConsolidation or {}
function KitchenConsolidation.resolveContainerByproducts(fullType)
    return RecipeContainerized.byproductLookup(fullType)
end

-- Minimal, defensive food logger (no pcall; safe in Kahlua runtime)
local function logFood(prefix, food)
    if not food then
        debug(prefix .. ": <nil>")
        return
    end

    local fullType = "?"
    if food.getFullType then
        fullType = tostring(food:getFullType())
    end

    local baseHunger = 0
    if food.getBaseHunger then
        baseHunger = food:getBaseHunger() or 0
    end

    local hunger = 0
    if food.getHungerChange then
        hunger = food:getHungerChange() or 0
    end

    debug(string.format(
        "%s fullType=%s baseHunger=%.2f hunger=%.2f",
        prefix,
        fullType,
        math.abs(baseHunger),
        math.abs(hunger)
    ))
end


function Recipe.OnCreate.KitchenConsolidation_Chop(items, result, player)
    debug("KitchenConsolidation_Chop ENTER")

    if not result or not items then
        debug("  ERROR: result or items missing")
        return
    end

    -- Collect only Food inputs (ignore kept tools)
    local foods = {}
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if instanceof(it, "Food") then
            table.insert(foods, it)
        end
    end

    if #foods == 0 then
        debug("  ERROR: no Food inputs found")
        return
    end

    -- For Chop, we expect exactly one food input
    local src = foods[1]

    debug("  SOURCE FOOD:")
    logFood("    src", src)

    -- Manually consume the source food item.
    -- Required because this recipe execution path does not auto-consume inputs.
    if player and src then
        local inv = player:getInventory()
        if inv and inv:contains(src) then
            inv:Remove(src)
            debug("  consumed source food from inventory")
        else
            debug("  WARNING: source food not found in inventory for consumption")
        end
    end

    -- --- Hunger / portion ---
    local base = math.abs(src:getBaseHunger())
    local cur  = math.abs(src:getHungerChange())
    local frac = 0
    if base > 0 then
        frac = cur / base
    end
    debug(string.format("  computed base=%.2f cur=%.2f frac=%.4f", base, cur, frac))

    -- Define result hunger based on source portion
    -- IMPORTANT: Do NOT modify baseHunger here; it is defined by the item script
    result:setHungChange(-base * frac)

    -- --- Nutrition (scale by portion) ---
    if result.setCalories and src.getCalories then
        result:setCalories((src:getCalories() or 0) * frac)
    end
    if result.setProteins and src.getProteins then
        result:setProteins((src:getProteins() or 0) * frac)
    end
    if result.setLipids and src.getLipids then
        result:setLipids((src:getLipids() or 0) * frac)
    end
    if result.setCarbohydrates and src.getCarbohydrates then
        result:setCarbohydrates((src:getCarbohydrates() or 0) * frac)
    end

    -- --- Freshness / rot ---
    -- Preserve age proportionally; do NOT reset freshness
    if result.setAge and src.getAge then
        result:setAge(src:getAge())
    end

    if result.setCooked and src.isCooked then
        result:setCooked(src:isCooked())
    end

    -- --- Boredom / unhappiness ---
    -- Small improvement for freshly chopped food
    if result.setBoredomChange and src.getBoredomChange then
        local srcBoredom = src:getBoredomChange() or 0
        -- Reduce boredom slightly (cannot be better than zero)
        result:setBoredomChange(math.min(0, srcBoredom - 5))
    end

    if result.setUnhappyChange and src.getUnhappyChange then
        local srcUnhappy = src:getUnhappyChange() or 0
        result:setUnhappyChange(math.min(0, srcUnhappy - 5))
    end

    -- --- Weight ---
    -- Weight scales with portion; must set custom + actual
    if result.setCustomWeight then
        result:setCustomWeight(true)
    end

    if result.setWeight and src.getWeight then
        result:setWeight(src:getWeight() * frac)
    end
    if result.setActualWeight and src.getActualWeight then
        result:setActualWeight(src:getActualWeight() * frac)
    end

    debug("  RESULT FOOD AFTER MUTATION:")
    logFood("    result", result)

    debug("KitchenConsolidation_Chop EXIT")
end

function Recipe.OnCreate.KitchenConsolidation_Combine_OnCreate(items, result, player)
    debug("KitchenConsolidation_Combine ENTER")

    if not player or not player.getInventory or not items or items:size() == 0 or not result then
        debug("  ERROR: missing player, items, or result")
        return
    end

    local inv = player:getInventory()
    if not inv or not inv.getItems then
        debug("  ERROR: inventory missing")
        return
    end

    local invItems = inv:getItems()
    if not invItems or not invItems.size then
        debug("  ERROR: inventory items missing")
        return
    end

    ----------------------------------------------------------------
    -- 1) Establish thumbprint from FIRST Food in `items`
    ----------------------------------------------------------------
    local thumb = nil
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and instanceof(it, "Food") then
            thumb = it
            break
        end
    end

    if not thumb then
        debug("  ERROR: no Food found in recipe items")
        return
    end

    local thumbType = thumb:getFullType()
    local thumbCooked = thumb.isCooked and thumb:isCooked() or false
    local thumbRotten = thumb.isRotten and thumb:isRotten() or false
    local thumbStale  = thumb.isStale and thumb:isStale() or false

    debug(string.format(
        "  thumbprint type=%s cooked=%s rotten=%s stale=%s",
        tostring(thumbType),
        tostring(thumbCooked),
        tostring(thumbRotten),
        tostring(thumbStale)
    ))

    ----------------------------------------------------------------
    -- 2) Scan inventory for matching Food instances (intent-aware)
    ----------------------------------------------------------------
    local sources = {}
    local seen = {}

    for i = 0, invItems:size() - 1 do
        local it = invItems:get(i)
        if it
           and instanceof(it, "Food")
           and it.getFullType
           and it:getFullType() == thumbType
           and it ~= result
           and not seen[it] then

            local cooked = it.isCooked and it:isCooked() or false
            local rotten = it.isRotten and it:isRotten() or false
            local stale  = it.isStale and it:isStale() or false

            if cooked == thumbCooked
               and rotten == thumbRotten
               and stale == thumbStale then

                local base = math.abs(it:getBaseHunger() or 0)
                local cur  = math.abs(it:getHungerChange() or 0)

                -- Only PARTIAL items participate
                if base > 0 and cur < base then
                    seen[it] = true
                    table.insert(sources, it)

                    debug(string.format(
                        "  source %s base=%.4f cur=%.4f",
                        tostring(it), base, cur
                    ))
                end
            end
        end
    end

    if #sources < 2 then
        debug("  ERROR: fewer than two matching Food sources")
        -- Defensive: remove ghost result if engine already created it
        if inv:contains(result) then
            inv:Remove(result)
        end
        return
    end

    debug("  total qualified sources=" .. tostring(#sources))

    ----------------------------------------------------------------
    -- 3) Unified combine math (pieces + containerized)
    ----------------------------------------------------------------
    local byps = KitchenConsolidation.resolveContainerByproducts(thumbType)
    local isContainerized = byps ~= nil

    -- Capacity per item
    local maxBase = math.abs(thumb:getBaseHunger() or 0)

    -- Sum total hunger
    local totalCur = 0
    local totalWeight = 0
    local totalActualWeight = 0
    local oldestAge = 0

    local anyDangerous = false
    local anyPoisoned  = false
    local anyTainted   = false

    for _, f in ipairs(sources) do
        local cur = math.abs(f:getHungerChange() or 0)
        totalCur = totalCur + cur

        if f.getWeight then totalWeight = totalWeight + (f:getWeight() or 0) end
        if f.getActualWeight then totalActualWeight = totalActualWeight + (f:getActualWeight() or 0) end
        if f.getAge then oldestAge = math.max(oldestAge, f:getAge() or 0) end

        if f.isDangerousUncooked and f:isDangerousUncooked() then anyDangerous = true end
        if f.isPoisoned and f:isPoisoned() then anyPoisoned = true end
        if f.isTainted and f:isTainted() then anyTainted = true end
    end

    debug(string.format("  total hunger=%.4f capacity=%.4f", totalCur, maxBase))

    ----------------------------------------------------------------
    -- 4) Remove all source items
    ----------------------------------------------------------------
    for _, f in ipairs(sources) do
        if inv:contains(f) then
            inv:Remove(f)
        end
    end
    debug("  removed all source Food instances")

    ----------------------------------------------------------------
    -- 5) Produce outputs
    ----------------------------------------------------------------
    local fullCount = math.floor(totalCur / maxBase)
    local remainder = totalCur - (fullCount * maxBase)

    -- Build outputs WITHOUT creating zero-hunger food items
    local outputs = {}

    -- Full items
    for i = 1, fullCount do
        local out
        if i == 1 then
            out = result            -- reuse engine-created item
        else
            out = inv:AddItem(thumbType)
        end

        if out then
            out:setHungChange(-maxBase)
            table.insert(outputs, out)
        end
    end

    -- Partial remainder (only if non-zero)
    if remainder > 0 then
        local out
        if fullCount == 0 then
            out = result            -- reuse engine-created item
        else
            out = inv:AddItem(thumbType)
        end

        if out then
            out:setHungChange(-remainder)
            table.insert(outputs, out)
        end
    end

    -- Apply properties to all outputs
    for _, out in ipairs(outputs) do
        out:setBaseHunger(-maxBase)
        if out.getHungerChange == nil then
            out:setHungChange(-maxBase)
        end

        if out.setAge then out:setAge(oldestAge) end
        if out.setCustomWeight then out:setCustomWeight(true) end

        local frac = math.abs(out:getHungerChange()) / totalCur
        if out.setWeight then out:setWeight(totalWeight * frac) end
        if out.setActualWeight then out:setActualWeight(totalActualWeight * frac) end

        if anyDangerous and out.setDangerousUncooked then out:setDangerousUncooked(true) end
        if anyPoisoned and out.setPoisoned then out:setPoisoned(true) end
        if anyTainted and out.setTainted then out:setTainted(true) end

        logFood("    output", out)
    end

    ----------------------------------------------------------------
    -- 6) Emit container byproducts (containers only)
    ----------------------------------------------------------------
    if isContainerized and byps then
        local empties = #sources - #outputs
        for i = 1, empties do
            for _, b in ipairs(byps) do
                inv:AddItem(b)
                debug("  emitted container byproduct: " .. tostring(b))
            end
        end
    end

    debug("KitchenConsolidation_Combine EXIT")
end

function Recipe.OnCanPerform.KitchenConsolidation_Combine_OnCanPerform(recipe, player, container)
    if KC_COMBINE_TRACE then
        trace("[KC Combine CanPerform] ENTER")
    end

    if not player or not player.getInventory then
        return false
    end

    local inv = player:getInventory()
    if not inv or not inv.getItems then
        return false
    end

    local items = inv:getItems()
    if not items or not items.size then
        return false
    end

    local counts = {}

    for i = 0, items:size() - 1 do
        local it = items:get(i)

        if it and instanceof(it, "Food")
           and it.getBaseHunger
           and it.getHungerChange
           and it.getFullType then

            local fullType = it:getFullType()
            local base = math.abs(it:getBaseHunger() or 0)
            local cur  = math.abs(it:getHungerChange() or 0)

            if KC_COMBINE_TRACE then
                trace(string.format(
                    "[KC Combine CanPerform] checking %s base=%.4f cur=%.4f",
                    tostring(fullType), base, cur
                ))
            end

            -- Use byproduct lookup to determine containerization
            local byps = RecipeContainerized.byproductLookup(fullType)
            local isContainerized = byps ~= nil

            local isPartial =
                (base > 0 and cur < base) or
                (isContainerized and cur > 0 and cur < base)

            if not isPartial then
                if KC_COMBINE_TRACE then
                    trace("  reject: not partial")
                end
            else
                local cooked = it.isCooked and it:isCooked() or false
                local rotten = it.isRotten and it:isRotten() or false
                local stale  = it.isStale and it:isStale() or false

                local key = table.concat({
                    fullType,
                    cooked and "1" or "0",
                    rotten and "1" or "0",
                    stale  and "1" or "0",
                }, "|")

                counts[key] = (counts[key] or 0) + 1

                if KC_COMBINE_TRACE then
                    trace(string.format(
                        "  ACCEPT key=%s count=%d",
                        key, counts[key]
                    ))
                end

                if counts[key] >= 2 then
                    if KC_COMBINE_TRACE then
                        trace("[KC Combine CanPerform] SUCCESS (>=2 matching items)")
                    end
                    return true
                end
            end
        elseif KC_COMBINE_TRACE then
            trace("[KC Combine CanPerform] skipping non-Food item")
        end
    end

    if KC_COMBINE_TRACE then
        trace("[KC Combine CanPerform] EXIT false (no qualifying pairs)")
    end
    return false
end
