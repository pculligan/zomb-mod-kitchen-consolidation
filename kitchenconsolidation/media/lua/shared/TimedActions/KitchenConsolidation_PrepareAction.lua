-- KitchenConsolidation_PrepareAction.lua
--
-- Generic timed action for preparing discrete food items into prepared forms
-- (e.g., FishFillet -> FishPieces, Cabbage -> CabbagePieces).
--
-- Key rule:
--   Prepared items preserve source consumption semantics.
--   The only added behavior is combinability (handled elsewhere).
--
-- This action does NOT aggregate hunger or normalize nutrition.

local Util = require("KitchenConsolidation_Util")
local ConsolidateAction = require("TimedActions/KitchenConsolidation_ConsolidateAction")

PrepareAction =
    ISBaseTimedAction:derive("PrepareAction")

function PrepareAction:new(player, sources, targetFullType)
    local o = ISBaseTimedAction.new(self, player)
    o.sources = sources
    o.targetFullType = targetFullType
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 100
    return o
end

function PrepareAction:isValid()
    if not self.sources or #self.sources == 0 then
        return false
    end

    local inv = self.character and self.character:getInventory()
    if not inv then
        return false
    end

    for _, item in ipairs(self.sources) do
        if not item then
            return false
        end

        -- Item must still be in the player's inventory
        if item:getContainer() ~= inv then
            return false
        end
    end

    return true
end

function PrepareAction:start()
    self:setActionAnim("Loot")
    self:setOverrideHandModels(nil, nil)
end

function PrepareAction:perform()
    local inv = self.character:getInventory()
    Util.debug("PrepareAction:perform starting for target " .. tostring(self.targetFullType))

    -- Determine worst-case freshness / poison state
    local minFresh = nil
    local maxAge = 0
    local isPoisoned = false

    -- Determine canonical FULL hunger from sources (engine-agnostic)
    local canonicalFullHunger = 0
    for _, src in ipairs(self.sources) do
        local cur = Util.getCurrentHunger(src)
        if cur then
            cur = math.abs(cur)
            if cur > 0 then
                canonicalFullHunger = canonicalFullHunger + cur
            end
        else
            Util.warn("PrepareAction: source has no readable hunger while computing KC_FullHunger")
        end
    end

    Util.debug(string.format(
        "PrepareAction: canonical FULL hunger from sources = %s",
        tostring(canonicalFullHunger)
    ))

    if canonicalFullHunger <= Util.EPS then
        Util.warn("PrepareAction: WARNING canonical FULL hunger from sources is zero")
    end

    for _, src in ipairs(self.sources) do
        if src.getAge and src:getAge() then
            maxAge = math.max(maxAge, src:getAge())
        end
        if src.isPoisoned and src:isPoisoned() then
            isPoisoned = true
        end
        if src.getOffAgeMax and src:getOffAgeMax() then
            if not minFresh then
                minFresh = src:getOffAgeMax()
            else
                minFresh = math.min(minFresh, src:getOffAgeMax())
            end
        end
    end

    -- Convert each source into a prepared item
    for _, src in ipairs(self.sources) do
        if inv:contains(src) then
            local prepared = inv:AddItem(self.targetFullType)
            Util.debug("PrepareAction: spawned prepared item = " .. tostring(prepared))
            if prepared then
                Util.debug("PrepareAction: prepared instanceof Food = " .. tostring(instanceof(prepared, "Food")))
                -- Store canonical full hunger on prepared item (mod-owned invariant)
                if canonicalFullHunger and canonicalFullHunger > Util.EPS then
                    prepared:getModData().KC_FullHunger = canonicalFullHunger
                else
                    Util.warn("PrepareAction: refusing to assign KC_FullHunger <= 0")
                end

                -- Preserve remaining hunger using authoritative helper
                local srcCur = Util.getCurrentHunger(src)
                if srcCur then
                    Util.debug("PrepareAction: applying remaining hunger " .. tostring(srcCur))
                    Util.setCurrentHunger(prepared, srcCur)
                else
                    Util.warn("PrepareAction: source has no readable hunger")
                end

                Util.debug(string.format(
                    "PrepareAction: prepared %s cur=%s full=%s",
                    tostring(self.targetFullType),
                    tostring(Util.getCurrentHunger(prepared)),
                    tostring(prepared:getModData().KC_FullHunger)
                ))
                Util.debug("PrepareAction: prepared modData = " .. tostring(prepared:getModData()))

                -- Preserve nutrition where supported (Food only)
                if instanceof(prepared, "Food") and instanceof(src, "Food") then
                    if prepared.setCalories and src.getCalories then
                        prepared:setCalories(src:getCalories())
                    end
                    if prepared.setProteins and src.getProteins then
                        prepared:setProteins(src:getProteins())
                    end
                    if prepared.setLipids and src.getLipids then
                        prepared:setLipids(src:getLipids())
                    end
                    if prepared.setCarbohydrates and src.getCarbohydrates then
                        prepared:setCarbohydrates(src:getCarbohydrates())
                    end
                end

                -- Apply worst-case freshness / age
                if maxAge > 0 and prepared.setAge then
                    prepared:setAge(maxAge)
                end
                if minFresh and prepared.setOffAgeMax then
                    prepared:setOffAgeMax(minFresh)
                end

                -- Force engine freshness state recompute (ensures Fresh/Stale tooltip correctness)
                if prepared.updateAge then
                    prepared:updateAge()
                end

                -- Propagate poison if supported
                if isPoisoned and prepared.setPoisoned then
                    prepared:setPoisoned(true)
                end
            end

            inv:Remove(src)
        end
    end

    -- Optional auto-consolidation (Option B): only run immediately after prepare,
    -- and only for the prepared item type.
    if SandboxVars
       and SandboxVars.KitchenConsolidation
       and SandboxVars.KitchenConsolidation.AutoConsolidate then

        Util.debug("PrepareAction: AutoConsolidate enabled; checking prepared item type only")

        -- In this action, sources are required to be in the player's inventory.
        -- Auto-consolidation therefore operates over the player's inventory only.
        local itemsJava = inv:getItems()
        if not itemsJava or itemsJava:size() < 2 then
            Util.debug("PrepareAction: AutoConsolidate skipped (inventory too small)")
        else
            -- Convert Java list -> Lua array for Util.buildMergeGroups()
            local allItems = {}
            for i = 0, itemsJava:size() - 1 do
                table.insert(allItems, itemsJava:get(i))
            end

            local groups = Util.buildMergeGroups(allItems)

            Util.debug(
                "PrepareAction: AutoConsolidate merge groups = "
                .. tostring(groups)
            )

            local dispatched = false

            for mergeKey, groupItems in pairs(groups) do
                Util.debug(
                    string.format(
                        "PrepareAction: inspecting merge group '%s' (%d items)",
                        tostring(mergeKey),
                        #groupItems
                    )
                )

                local fullType = tostring(mergeKey):match("^[^|]+")

                if fullType == self.targetFullType then
                    Util.debug(
                        string.format(
                            "PrepareAction: AutoConsolidate matched target %s with %d items",
                            tostring(fullType),
                            #groupItems
                        )
                    )

                    if #groupItems >= 2 then
                        Util.debug(
                            "PrepareAction: AutoConsolidate dispatching ConsolidateAction for "
                            .. tostring(fullType)
                        )
                        ISTimedActionQueue.add(
                            ConsolidateAction:new(self.character, groupItems)
                        )
                        dispatched = true
                    else
                        Util.debug(
                            "PrepareAction: AutoConsolidate skipped (only "
                            .. tostring(#groupItems)
                            .. " item)"
                        )
                    end

                    break
                end
            end

            if not dispatched then
                Util.debug("PrepareAction: AutoConsolidate did not dispatch any action")
            end
        end
    end

    Util.debug("PrepareAction:perform complete for " .. tostring(self.targetFullType))

    ISBaseTimedAction.perform(self)
end

return PrepareAction
