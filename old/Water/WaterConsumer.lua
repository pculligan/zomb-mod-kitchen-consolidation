-- WaterConsumer.lua
-- Scaffolding connector representing a generic water consumer.
--
-- IMPORTANT:
-- This connector is intentionally minimal. It exists to validate:
-- - consumer participation in networks
-- - source + consumer coexistence
-- - registry merge/split behavior with demand present
--
-- It is NOT a final gameplay object.
-- Concrete consumers (Sink, Shower, IrrigationEmitter, etc.)
-- will evolve from or replace this later.

local BaseConnector = require("flow/BaseConnector")
local Registry      = require("topology/net/Registry")

-- Runtime helpers (singleton)
local runtime = require("infra/Runtime")
local log     = runtime and runtime.Logger
local guard   = runtime and runtime.Guard

local Allocation = require("core/domain/Allocation")
local PlanApplicationResult = require("core/domain/PlanApplicationResult")

local WaterConsumer = {}
WaterConsumer.__index = WaterConsumer
setmetatable(WaterConsumer, { __index = BaseConnector })

-- Allocation strategy (default: sequential)
WaterConsumer.allocationStrategy = "sequential"

function WaterConsumer.setAllocationStrategy(strategy)
    guard.assured(
        strategy == "sequential"
        or strategy == "weighted"
        or strategy == "leveling",
        "Unknown allocation strategy: " .. tostring(strategy)
    )
    WaterConsumer.allocationStrategy = strategy
end

----------------------------------------------------------------
-- Water Quality / Taint Dominance
----------------------------------------------------------------

-- Dominance order (higher index = worse)
local QUALITY_ORDER = {
    clean   = 1,
    tainted = 2,
    toxic   = 3,
}

local function dominantQuality(providers)
    local worst = QUALITY_ORDER.clean
    local label = "clean"

    for _, node in ipairs(providers) do
        local caps = node.capabilities
            or (node.connector and node.connector.capabilities)

        local q = caps and caps.quality
        local rank = QUALITY_ORDER[q or "clean"] or QUALITY_ORDER.clean

        if rank > worst then
            worst = rank
            label = q
        end
    end

    return label
end

----------------------------------------------------------------
-- Water Request
----------------------------------------------------------------

-- Request water from the network.
-- Pure coordination only (no mutation).
-- Returns:
-- {
--   ok        : boolean,
--   reason    : string,
--   requested : number,
--   fulfilled : number,
--   providers : { node, ... },
--   plan      : { { provider=node, amount=n }, ... }
-- }
function WaterConsumer:requestWater(amount)
    guard.assured(type(amount) == "number" and amount > 0, "requestWater requires positive amount")

    -- Must be attached to a node and network
    if not self.node or not self.node.network then
        return {
            ok = false,
            reason = "not_attached",
            requested = amount,
            fulfilled = 0,
            providers = {},
            plan = {}
        }
    end

    local network = self.node.network
    local providers = {}

    if log then
        log.debug("requestWater: scanning network nodes")
        log.debug("network.nodes = " .. tostring(network.nodes))
    end

    -- Discover provider nodes in the same network
    for key, node in pairs(network.nodes) do
        if log then
            log.debug("node key=" .. tostring(key)
                .. " node=" .. tostring(node)
                .. " self=" .. tostring(self.node))
        end

        if node ~= self.node then
            local caps = node.capabilities
                or (node.connector and node.connector.capabilities)

            if log then
                log.debug(
                    "  caps=" .. tostring(caps)
                    .. " provide=" .. tostring(caps and caps.provide)
                )
            end

            if caps and caps.provide then
                table.insert(providers, node)
            end
        end
    end

    if log then
        log.debug("requestWater: providers found = " .. tostring(#providers))
    end

    if #providers == 0 then
        return {
            ok = false,
            reason = "no_providers",
            requested = amount,
            fulfilled = 0,
            providers = {},
            plan = {}
        }
    end

    -- Build provider availability list
    local providerInfos = {}
    for _, node in ipairs(providers) do
        local connector = node.connector
        local available = 0

        if connector
           and connector.isDrainable
           and connector:isDrainable("Water")
           and connector.getAvailable
        then
            available = connector:getAvailable("Water") or 0
        end

        providerInfos[#providerInfos + 1] = {
            node = node,
            available = available
        }
    end

    -- Allocate using selected strategy
    local plan, fulfilled
    if WaterConsumer.allocationStrategy == "weighted" then
        plan, fulfilled = Allocation.weighted(providerInfos, amount)
    elseif WaterConsumer.allocationStrategy == "leveling" then
        plan, fulfilled = Allocation.leveling(providerInfos, amount)
    else
        plan, fulfilled = Allocation.sequential(providerInfos, amount)
    end

    if log then
        log.debug(
            "requestWater(" .. tostring(amount) .. ") -> fulfilled="
            .. tostring(fulfilled)
            .. " providers=" .. tostring(#providers)
        )
    end

    local quality = dominantQuality(providers)

    return {
        ok = (fulfilled > 0),
        reason = (fulfilled == amount and "fulfilled" or "partial"),
        requested = amount,
        fulfilled = fulfilled,
        quality = quality,
        providers = providers,
        plan = plan
    }
end

----------------------------------------------------------------
-- Plan Application (Mutation Phase)
----------------------------------------------------------------

-- Apply a previously generated plan.
-- Best-effort: attempts all drains, records failures.
-- Does NOT recompute availability or quality.
function WaterConsumer:applyPlan(planResult)
    guard.assured(type(planResult) == "table", "applyPlan requires planResult")

    local result = PlanApplicationResult.new(planResult.requested)
    if not planResult.plan then
        return result
    end

    local failed = {}

    -- First pass: apply plan in order
    for _, entry in ipairs(planResult.plan) do
        local node = entry.provider
        local amount = entry.amount
        local connector = node and node.connector

        if not connector or not connector.drain then
            failed[node] = true
            result:recordFailure(node, "no_drain_method")
        else
            local ok, reason = connector:drain(self.resource, amount)
            if ok then
                result:recordSuccess(amount)
            else
                failed[node] = true
                result:recordFailure(node, reason or "drain_failed")
            end
        end
    end

    -- Fallback pass: try remaining providers if nothing applied
    if result.applied == 0 and next(failed) ~= nil then
        for _, entry in ipairs(planResult.plan) do
            local node = entry.provider
            if not failed[node] then
                local connector = node and node.connector
                if connector and connector.drain then
                    local ok = connector:drain(self.resource, entry.amount)
                    if ok then
                        result:recordSuccess(entry.amount)
                    end
                end
            end
        end
    end

    return result
end

----------------------------------------------------------------
-- Construction
----------------------------------------------------------------

-- opts:
--   id       : unique connector id
--   object   : optional observed world object (may be nil for scaffolding)
--   position : { x, y, z }
function WaterConsumer.new(opts)
    guard.assured(opts ~= nil, "WaterConsumer.new requires opts")
    guard.assured(opts.position ~= nil, "WaterConsumer requires a position")

    local self = BaseConnector.new({
        id = opts.id,
        resource = "Water",
        position = opts.position,
        observed = opts.object, -- may be nil for dev scaffolding
        capabilities = {
            provide = false,
            consume = true,
            store   = false,
        }
    })

    setmetatable(self, WaterConsumer)

    return self
end

----------------------------------------------------------------
-- Eligibility
----------------------------------------------------------------

-- Generic consumer is always eligible while attached.
-- Real consumers will override this (e.g. broken sink, valve closed).
function WaterConsumer:isEligible()
    return true
end

----------------------------------------------------------------
-- Lifecycle Hooks
----------------------------------------------------------------

function WaterConsumer:onAttach()
    -- IMPORTANT: call BaseConnector lifecycle first
    BaseConnector.onAttach(self)

    if log then
        log.debug("Attaching WaterConsumer " .. tostring(self.id))
    end
end

function WaterConsumer:onDetach()
    -- IMPORTANT: call BaseConnector lifecycle first
    BaseConnector.onDetach(self)

    if log then
        log.debug("Detaching WaterConsumer " .. tostring(self.id))
    end
end

function WaterConsumer:onActivate()
    if log then
        log.debug("WaterConsumer activated " .. tostring(self.id))
    end
end

function WaterConsumer:onDeactivate()
    if log then
        log.debug("WaterConsumer deactivated " .. tostring(self.id))
    end
end

----------------------------------------------------------------
-- Export
----------------------------------------------------------------

return WaterConsumer
