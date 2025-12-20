-- KitchenConsolidation_Util.lua
-- Shared deterministic utility functions
-- Authoritative for Phase 1 behavior
-- See mod-spec.md: Design and Architecture / Core Functions

local KitchenConsolidation_Util = {}

-- ---------------------------------------------------------------------------
-- Logging (zero‑overhead when disabled)
-- ---------------------------------------------------------------------------

local LOGLEVELS = {
  TRACE = 1,
  DEBUG = 2,
  WARN  = 3,
  ERROR = 4
}

local function _noop(_) end
local function _print(msg)
    print("[KitchenConsolidation] " .. tostring(msg))
end
local function _warn(msg)
    print("[KitchenConsolidation][WARN] " .. tostring(msg))
end
local function _error(msg)
    print("[KitchenConsolidation][ERROR] " .. tostring(msg))
end

KitchenConsolidation_Util.trace = _noop
KitchenConsolidation_Util.debug = _noop
KitchenConsolidation_Util.warn  = _warn
KitchenConsolidation_Util.error = _error

function KitchenConsolidation_Util.setLogLevel(level)
    if level == LOGLEVELS.TRACE then
        KitchenConsolidation_Util.trace = _print
        KitchenConsolidation_Util.debug = _print
        KitchenConsolidation_Util.warn  = _warn
        KitchenConsolidation_Util.error = _error
    elseif level == LOGLEVELS.DEBUG then
        KitchenConsolidation_Util.trace = _noop
        KitchenConsolidation_Util.debug = _print
        KitchenConsolidation_Util.warn  = _warn
        KitchenConsolidation_Util.error = _error
    elseif level == LOGLEVELS.WARN then
        KitchenConsolidation_Util.trace = _noop
        KitchenConsolidation_Util.debug = _noop
        KitchenConsolidation_Util.warn  = _warn
        KitchenConsolidation_Util.error = _error
    elseif level == LOGLEVELS.ERROR then
        KitchenConsolidation_Util.trace = _noop
        KitchenConsolidation_Util.debug = _noop
        KitchenConsolidation_Util.warn  = _noop
        KitchenConsolidation_Util.error = _error
    else
        -- Unknown level, default to WARN
        KitchenConsolidation_Util.trace = _noop
        KitchenConsolidation_Util.debug = _noop
        KitchenConsolidation_Util.warn  = _warn
        KitchenConsolidation_Util.error = _error
    end
end

-- Default log level is WARN
KitchenConsolidation_Util.setLogLevel(LOGLEVELS.TRACE)

-- Deprecated compatibility wrapper
function KitchenConsolidation_Util.setDebug(enabled)
    if enabled then
        KitchenConsolidation_Util.setLogLevel(LOGLEVELS.DEBUG)
    else
        KitchenConsolidation_Util.setLogLevel(LOGLEVELS.WARN)
    end
end

KitchenConsolidation_Util.LOGLEVELS = LOGLEVELS

local Items = require("KitchenConsolidation_ConsolidateItems")

-- ---------------------------------------------------------------------------
-- Hunger access helpers (authoritative, defensive)
-- ---------------------------------------------------------------------------

function KitchenConsolidation_Util.getCurrentHunger(item)
    if not item then
        KitchenConsolidation_Util.debug("getCurrentHunger: item=nil")
        return nil
    end

    if item.getHungChange then
        local v = item:getHungChange()
        KitchenConsolidation_Util.debug("getCurrentHunger(getHungChange)=" .. tostring(v))
        return v
    end

    if item.getHungerChange then
        local v = item:getHungerChange()
        KitchenConsolidation_Util.debug("getCurrentHunger(getHungerChange)=" .. tostring(v))
        return v
    end

    KitchenConsolidation_Util.warn("getCurrentHunger: no hunger getter on item " .. tostring(item:getFullType()))
    return nil
end

function KitchenConsolidation_Util.setCurrentHunger(item, value)
    if not item then
        KitchenConsolidation_Util.warn("setCurrentHunger: item=nil")
        return false
    end

    KitchenConsolidation_Util.debug(
        "setCurrentHunger: attempting to set " ..
        tostring(value) ..
        " on " .. tostring(item:getFullType())
    )

    if item.setHungChange then
        item:setHungChange(value)
        KitchenConsolidation_Util.debug("setCurrentHunger(setHungChange) OK")
        return true
    end

    if item.setHungerChange then
        item:setHungerChange(value)
        KitchenConsolidation_Util.debug("setCurrentHunger(setHungerChange) OK")
        return true
    end

    KitchenConsolidation_Util.warn("setCurrentHunger: no hunger setter on item " .. tostring(item:getFullType()))
    return false
end

-- ---------------------------------------------------------------------------
-- Constants / Configuration
-- ---------------------------------------------------------------------------

-- Epsilon for floating-point comparisons
KitchenConsolidation_Util.EPS = 0.0001

KitchenConsolidation_Util.MERGEABLE_WHITELIST = Items.MERGEABLE_WHITELIST
KitchenConsolidation_Util.BYPRODUCT_ON_EMPTY = Items.BYPRODUCT_ON_EMPTY

-- ---------------------------------------------------------------------------
-- Quantity aggregation (KC_FullHunger-based, authoritative)
-- ---------------------------------------------------------------------------

function KitchenConsolidation_Util.computeFraction(item)
    if not instanceof(item, "Food") then
        KitchenConsolidation_Util.trace("computeFraction: not Food")
        return nil
    end

    local md = item:getModData()
    local full = md and md.KC_FullHunger

    KitchenConsolidation_Util.trace(
        "computeFraction: full=" .. tostring(full) ..
        " for " .. tostring(item:getFullType())
    )

    if not full or full <= KitchenConsolidation_Util.EPS then
        KitchenConsolidation_Util.debug("computeFraction: missing/invalid KC_FullHunger")
        return nil
    end

    local cur = KitchenConsolidation_Util.getCurrentHunger(item)
    if not cur then
        KitchenConsolidation_Util.trace("computeFraction: cur=nil")
        return nil
    end

    cur = math.abs(cur)

    if cur <= KitchenConsolidation_Util.EPS then
        KitchenConsolidation_Util.trace("computeFraction: cur <= EPS")
        return nil
    end

    local frac = cur / full
    KitchenConsolidation_Util.trace("computeFraction: frac=" .. tostring(frac))
    return frac
end

function KitchenConsolidation_Util.isEligibleFoodItem(item)
    if not instanceof(item, "Food") then
        KitchenConsolidation_Util.trace("isEligible: not Food")
        return false
    end

    local fullType = item:getFullType()
    if not fullType then
        KitchenConsolidation_Util.trace("isEligible: missing fullType")
        return false
    end

    KitchenConsolidation_Util.trace("isEligible: checking " .. fullType)

    -- Auto-whitelist all KitchenConsolidation prepared items
    local isKC = (string.sub(fullType, 1, #"KitchenConsolidation.") == "KitchenConsolidation.")
    KitchenConsolidation_Util.trace("isEligible: isKC=" .. tostring(isKC))

    -- Non-KC items must be explicitly whitelisted
    if not isKC and not KitchenConsolidation_Util.MERGEABLE_WHITELIST[fullType] then
        KitchenConsolidation_Util.trace("isEligible: not whitelisted")
        return false
    end

    if item.isRotten and item:isRotten() then
        KitchenConsolidation_Util.debug("isEligible: item is rotten")
        return false
    end

    local freshness = KitchenConsolidation_Util.getFreshnessBucket(item)
    if freshness == "rotten" then
        KitchenConsolidation_Util.debug("isEligible: rejected due to rotten freshness bucket")
        return false
    end
    if freshness == "unknown" then
        KitchenConsolidation_Util.debug("isEligible: rejected due to unknown freshness bucket")
        return false
    end

    local frac = KitchenConsolidation_Util.computeFraction(item)
    if not frac then
        KitchenConsolidation_Util.debug("isEligible: rejected due to missing KC_FullHunger")
        return false
    end

    KitchenConsolidation_Util.trace(
        "isEligible: frac=" .. tostring(frac) ..
        " EPS=" .. tostring(KitchenConsolidation_Util.EPS)
    )

    if frac <= KitchenConsolidation_Util.EPS then
        KitchenConsolidation_Util.debug("isEligible: frac <= EPS")
        return false
    end

    if frac >= (1.0 - KitchenConsolidation_Util.EPS) then
        KitchenConsolidation_Util.debug("isEligible: frac >= 1-EPS (full item)")
        return false
    end

    KitchenConsolidation_Util.debug("isEligible: ACCEPTED " .. fullType)
    return true
end

-- ---------------------------------------------------------------------------
-- Grouping
-- ---------------------------------------------------------------------------

function KitchenConsolidation_Util.buildMergeKey(item)
    -- Group by:
    --  - fullType
    --  - cooked/raw
    --  - burnt/ok
    --  - freshness bucket (fresh/stale/rotten)

    local cooked = false
    local burnt = false

    if item.isCooked then
        cooked = item:isCooked()
    end

    if item.isBurnt then
        burnt = item:isBurnt()
    end

    local freshness = KitchenConsolidation_Util.getFreshnessBucket(item)

    KitchenConsolidation_Util.trace(string.format(
        "buildMergeKey: %s cooked=%s burnt=%s freshness=%s",
        tostring(item:getFullType()),
        tostring(cooked),
        tostring(burnt),
        tostring(freshness)
    ))

    return table.concat({
        item:getFullType(),
        cooked and "cooked" or "raw",
        burnt and "burnt" or "ok",
        freshness
    }, "|")
end

function KitchenConsolidation_Util.buildMergeGroups(items)
    local groups = {}
    -- Authoritative grouping with HARD invariants:
    -- same fullType, same cooked/raw, same burnt/ok, same freshness bucket

    local keyState = {} -- key -> { freshness, cooked, burnt }

    for _, item in ipairs(items) do
        local key = KitchenConsolidation_Util.buildMergeKey(item)
        local cooked = item.isCooked and item:isCooked() or false
        local burnt  = item.isBurnt  and item:isBurnt()  or false
        local freshness = KitchenConsolidation_Util.getFreshnessBucket(item)

        -- Hard exclusion: unknown freshness can never be merged
        if freshness == "unknown" then
            KitchenConsolidation_Util.trace(
                "buildMergeGroups: EXCLUDE " .. tostring(item:getFullType()) .. " (unknown freshness)"
            )
        else
            local state = keyState[key]

            if not state then
                -- First item defines the invariant for this group
                keyState[key] = {
                    freshness = freshness,
                    cooked    = cooked,
                    burnt     = burnt
                }
                groups[key] = { item }
            else
                -- Hard invariant enforcement
                if state.freshness ~= freshness then
                    KitchenConsolidation_Util.trace(
                        "buildMergeGroups: EXCLUDE " .. tostring(item:getFullType()) ..
                        " (freshness mismatch: got=" .. tostring(freshness) ..
                        ", expected=" .. tostring(state.freshness) .. ")"
                    )
                elseif state.cooked ~= cooked then
                    KitchenConsolidation_Util.trace(
                        "buildMergeGroups: EXCLUDE " .. tostring(item:getFullType()) ..
                        " (cooked mismatch: got=" .. tostring(cooked) ..
                        ", expected=" .. tostring(state.cooked) .. ")"
                    )
                elseif state.burnt ~= burnt then
                    KitchenConsolidation_Util.trace(
                        "buildMergeGroups: EXCLUDE " .. tostring(item:getFullType()) ..
                        " (burnt mismatch: got=" .. tostring(burnt) ..
                        ", expected=" .. tostring(state.burnt) .. ")"
                    )
                else
                    table.insert(groups[key], item)
                end
            end
        end
    end

    return groups
end

-- ---------------------------------------------------------------------------
-- Worst-Case State Application
-- ---------------------------------------------------------------------------

function KitchenConsolidation_Util.applyWorstCaseFreshness(sourceItems, resultItem)
    if not resultItem or not sourceItems then return end
    if not resultItem.getAge then return end

    KitchenConsolidation_Util.trace("applyWorstCaseFreshness: starting")

    local worstAge = 0
    local offAge = nil
    local offAgeMax = nil

    for _, item in ipairs(sourceItems) do
        if item.getAge then
            worstAge = math.max(worstAge, item:getAge())
        end
        if item.getOffAge then
            offAge = offAge and math.min(offAge, item:getOffAge()) or item:getOffAge()
        end
        if item.getOffAgeMax then
            offAgeMax = offAgeMax and math.min(offAgeMax, item:getOffAgeMax()) or item:getOffAgeMax()
        end
    end

    if resultItem.setAge then
        resultItem:setAge(worstAge)
    end
    if offAge and resultItem.setOffAge then
        resultItem:setOffAge(offAge)
    end
    if offAgeMax and resultItem.setOffAgeMax then
        resultItem:setOffAgeMax(offAgeMax)
    end

    KitchenConsolidation_Util.trace("applyWorstCaseFreshness: done")
end

function KitchenConsolidation_Util.applyWorstCaseSickness(sourceItems, resultItem)
    if not resultItem or not sourceItems then return end

    KitchenConsolidation_Util.trace("applyWorstCaseSickness: starting")

    local poisoned = false
    local tainted = false

    for _, item in ipairs(sourceItems) do
        if item.isPoisoned and item:isPoisoned() then
            poisoned = true
        end
        if item.isTainted and item:isTainted() then
            tainted = true
        end
    end

    if poisoned and resultItem.setPoisoned then
        resultItem:setPoisoned(true)
    end
    if tainted and resultItem.setTainted then
        resultItem:setTainted(true)
    end

    KitchenConsolidation_Util.trace("applyWorstCaseSickness: done")
end

-- ---------------------------------------------------------------------------
-- Freshness Bucketing (authoritative, non-improving)
-- ---------------------------------------------------------------------------

function KitchenConsolidation_Util.getFreshnessBucket(item)
    if not item or not item.getAge or not item.getOffAge or not item.getOffAgeMax then
        return "unknown"
    end

    local age = item:getAge()
    local offAge = item:getOffAge()
    local offAgeMax = item:getOffAgeMax()

    -- Defensive logging
    KitchenConsolidation_Util.trace(string.format(
        "getFreshnessBucket: %s age=%.3f offAge=%.3f offAgeMax=%.3f",
        tostring(item:getFullType()),
        tonumber(age) or -1,
        tonumber(offAge) or -1,
        tonumber(offAgeMax) or -1
    ))

    if age >= offAgeMax then
        return "rotten"
    elseif age >= offAge then
        return "stale"
    else
        return "fresh"
    end
end

-- ---------------------------------------------------------------------------
-- Merge State Introspection (Freshness‑Aware, Non‑Poison)
-- ---------------------------------------------------------------------------

function KitchenConsolidation_Util.getMergeState(item)
    if not item then return nil end

    local cooked = item.isCooked and item:isCooked() or false
    local burnt  = item.isBurnt  and item:isBurnt()  or false
    local freshness = KitchenConsolidation_Util.getFreshnessBucket(item)

    return {
        fullType  = item:getFullType(),
        cooked    = cooked,
        burnt     = burnt,
        freshness = freshness
    }
end

function KitchenConsolidation_Util.logMergeState(prefix, item)
    local s = KitchenConsolidation_Util.getMergeState(item)
    if not s then return end

    KitchenConsolidation_Util.debug(string.format(
        "%s mergeState: type=%s cooked=%s burnt=%s freshness=%s",
        prefix,
        tostring(s.fullType),
        tostring(s.cooked),
        tostring(s.burnt),
        tostring(s.freshness)
    ))
end

-- ---------------------------------------------------------------------------
-- Weight & Nutrition
-- ---------------------------------------------------------------------------

function KitchenConsolidation_Util.applyCappedWeight(sourceItems, resultItem)
    if not resultItem or not sourceItems then return end
    if not resultItem.getActualWeight or not resultItem.setWeight then return end

    local totalWeight = 0
    local fullWeight = resultItem:getActualWeight()
    if not fullWeight then return end

    for _, item in ipairs(sourceItems) do
        local frac = KitchenConsolidation_Util.computeFraction(item)
        if frac and item.getActualWeight then
            totalWeight = totalWeight + (item:getActualWeight() * frac)
        end
    end

    local finalWeight = math.min(totalWeight, fullWeight)
    resultItem:setWeight(finalWeight)
end

-- ---------------------------------------------------------------------------
-- Empty Container Accounting
-- ---------------------------------------------------------------------------

function KitchenConsolidation_Util.getByproductForEmptiedItem(item)
    if not item then return nil end
    return KitchenConsolidation_Util.BYPRODUCT_ON_EMPTY[item:getFullType()]
end

return KitchenConsolidation_Util
