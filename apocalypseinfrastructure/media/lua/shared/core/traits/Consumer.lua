-- Consumer.lua
-- Trait: enables an entity to consume a resource from its network.
-- Extracted from WaterConsumer; generic and resource-agnostic.

local Allocation = require("core/domain/Allocation")
local PlanApplicationResult = require("core/domain/PlanApplicationResult")

local runtime = require("infra/Runtime")
local log     = runtime and runtime.Logger
local guard   = runtime and runtime.Guard

local Resource   = require("core/domain/Resource")
local Capability = require("core/domain/Capability")

local ConsumerCapability = Capability.ConsumerCapability
local Capabilities       = Capability.Capabilities

local Consumer = {}
Consumer.__index = Consumer

----------------------------------------------------------------
-- Allocation strategy (shared across all consumers)
----------------------------------------------------------------

Consumer.allocationStrategy = "sequential"

function Consumer.setAllocationStrategy(strategy)
    guard.assured(
        strategy == "sequential"
        or strategy == "weighted"
        or strategy == "leveling",
        "Unknown allocation strategy: " .. tostring(strategy)
    )
    Consumer.allocationStrategy = strategy
end

----------------------------------------------------------------
-- Quality / dominance (generic)
----------------------------------------------------------------

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
-- Apply Consumer role (generic)
----------------------------------------------------------------
-- opts:
--   capability : ConsumerCapability (required)
function Consumer.apply(target, opts)
    assert(target, "Consumer.apply requires target")
    assert(opts and opts.capability, "Consumer.apply requires opts.capability")

    -- Ensure entity has Capabilities container
    if not target.capabilities then
        target.capabilities = Capabilities.new()
    end

    -- Register consumer capability
    target.capabilities:addConsumer(opts.capability)

    -- Bind consumer-facing API
    target.request   = Consumer.request
    target.applyPlan = Consumer.applyPlan
end

----------------------------------------------------------------
-- Request phase (pure coordination)
----------------------------------------------------------------

function Consumer:request(amount)
    if log then
        log.debug("Consumer.request ENTER", self.id, "amount=", amount)
    end

    guard.assured(type(amount) == "number" and amount > 0, "request requires positive amount")

    local consumerCap = next(self.capabilities.consumes)
    assert(consumerCap, "Consumer has no consume capability")
    local resource = consumerCap

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
        log.debug("request: scanning network nodes")
    end

    for _, node in pairs(network.nodes) do
        if node ~= self.node then
            local entity = node.entity or node.connector or node
            local caps = entity and entity.capabilities
            if caps and caps:getProvider(resource) then
                table.insert(providers, node)
            end
        end
    end

    if log then
        log.debug("request: found providers", #providers)
        for _, n in ipairs(providers) do
            log.debug("request: provider node", n)
        end
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

    local providerInfos = {}
    for _, node in ipairs(providers) do
        local entity = node.entity or node.connector or node
        local caps = entity and entity.capabilities
        local store = caps and caps:getStore(resource)
        local available = store and store.current or 0
        providerInfos[#providerInfos + 1] = { node = node, available = available }
    end

    local plan, fulfilled
    if Consumer.allocationStrategy == "weighted" then
        plan, fulfilled = Allocation.weighted(providerInfos, amount)
    elseif Consumer.allocationStrategy == "leveling" then
        plan, fulfilled = Allocation.leveling(providerInfos, amount)
    else
        plan, fulfilled = Allocation.sequential(providerInfos, amount)
    end

    if log then
        log.debug("request: allocation strategy", Consumer.allocationStrategy)
        log.debug("request: fulfilled", fulfilled, "of", amount)
        for i, entry in ipairs(plan) do
            log.debug("request: plan entry", i, "provider=", entry.provider, "amount=", entry.amount)
        end
        log.debug("Consumer.request EXIT", "requested=", amount, "fulfilled=", fulfilled, "plan_entries=", #plan)
    end

    return {
        ok = (fulfilled > 0),
        reason = (fulfilled == amount and "fulfilled" or "partial"),
        requested = amount,
        fulfilled = fulfilled,
        quality = dominantQuality(providers),
        providers = providers,
        plan = plan
    }
end

----------------------------------------------------------------
-- Plan application (mutation)
----------------------------------------------------------------

function Consumer:applyPlan(planResult)
    if log then
        log.debug(
            "Consumer.applyPlan ENTER",
            self.id,
            "requested=", planResult and planResult.requested,
            "plan_entries=", planResult and planResult.plan and #planResult.plan or 0
        )
        log.debug("applyPlan: requested", planResult.requested, "target", planResult.fulfilled or planResult.requested)
        log.debug("applyPlan: plan entries", planResult.plan and #planResult.plan or 0)
    end

    guard.assured(type(planResult) == "table", "applyPlan requires planResult")

    local consumerCap = next(self.capabilities.consumes)
    assert(consumerCap, "Consumer has no consume capability")
    local resource = consumerCap

    local target = planResult.fulfilled or planResult.requested
    local result = PlanApplicationResult.new(target)
    if not planResult.plan then
        return result
    end

    local failed = {}
    local applied = 0

    for _, entry in ipairs(planResult.plan) do
        local node   = entry.provider
        local amount = entry.amount

        local entity = node and node.entity
        local caps   = entity and entity.capabilities
        local providerCap = caps and caps:getProvider(resource)

        if not providerCap or not providerCap.enabled then
            failed[node] = true
            result:recordFailure(node, "provider_disabled")
        elseif not entity.drain then
            failed[node] = true
            result:recordFailure(node, "no_drain_method")
        else
            if log then log.debug("applyPlan: draining provider", node, "amount=", amount) end
            local ok, reason = entity:drain(resource, amount)
            if ok then
                result:recordSuccess(amount)
                applied = applied + amount
                if log then log.debug("applyPlan: drain success", node, "amount=", amount) end
            else
                failed[node] = true
                result:recordFailure(node, reason or "drain_failed")
                if log then log.debug("applyPlan: drain failed", node, "reason=", reason) end
            end
        end
    end

    local remaining = target - applied
    if remaining > 0 then
        for _, node in pairs(self.node.network.nodes) do
            if remaining <= 0 then break end
            if node ~= self.node and not failed[node] then
                local entity = node.entity
                local caps   = entity and entity.capabilities
                local providerCap = caps and caps:getProvider(resource)

                if providerCap and providerCap.enabled and entity.drain then
                    if log then log.debug("applyPlan: fallback draining provider", node, "amount=", remaining) end
                    local ok, reason = entity:drain(resource, remaining)
                    if ok then
                        result:recordSuccess(remaining)
                        applied = applied + remaining
                        if log then log.debug("applyPlan: fallback success", node, "amount=", remaining) end
                        remaining = 0
                    else
                        failed[node] = true
                        result:recordFailure(node, reason or "drain_failed")
                        if log then log.debug("applyPlan: fallback failed", node, "reason=", reason) end
                    end
                end
            end
        end
    end

    if result.applied == nil then
        result.applied = applied
    end

    if log then
        log.debug("Consumer.applyPlan EXIT", self.id, "applied=", result.applied)
    end

    return result
end

----------------------------------------------------------------
-- Resource-specific wrappers (Option-2)
----------------------------------------------------------------

function Consumer.water(target, opts)
    opts = opts or {}
    return Consumer.apply(target, { capability = Capability.WaterConsumerCapability(opts) })
end

function Consumer.fuel(target, opts)
    opts = opts or {}
    return Consumer.apply(target, { capability = Capability.FuelConsumerCapability(opts) })
end

function Consumer.propane(target, opts)
    opts = opts or {}
    return Consumer.apply(target, { capability = Capability.PropaneConsumerCapability(opts) })
end

function Consumer.electricity(target, opts)
    opts = opts or {}
    return Consumer.apply(target, { capability = Capability.ElectricityConsumerCapability(opts) })
end

return Consumer