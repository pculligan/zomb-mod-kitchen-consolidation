-- Allocation.lua
-- Resource-agnostic allocation strategies.
-- Lua 5.1 compatible. No engine or PZ dependencies.
--
-- Strategies:
--
-- sequential:
--   Drain providers in iteration order until request satisfied.
--   Order-dependent. No fairness guarantees.
--
-- proportional_quantity:
--   True weighted allocation by availability.
--   drain_i = request * (avail_i / total_avail)
--   Capped by availability, with remainder absorbed deterministically.
--
-- proportional_distance:
--   Weighted by inverse distance (closer providers contribute more).
--   Requires opts.distances[node] = number (>= 0).
--
-- leveling:
--   Drain the fullest providers first to equalize all providers downward.

local Allocation = {}

-- Convenience dispatcher (optional)
function Allocation.plan(strategy, providers, amount, opts)
    local fn = Allocation[strategy]
    assert(type(fn) == "function", "Unknown allocation strategy: " .. tostring(strategy))
    return fn(providers, amount, opts)
end

function Allocation.sequential(providers, amount)
    local remaining = amount
    local plan = {}

    for _, p in ipairs(providers) do
        if remaining <= 0 then break end
        local node = p.node or p
        local available = p.available or remaining
        local take = math.min(available, remaining)
        if take > 0 then
            plan[#plan + 1] = { provider = p.provider or node, amount = take }
            remaining = remaining - take
        end
    end

    return plan, (amount - remaining)
end

function Allocation.proportional_quantity(providers, amount)
    local entries = {}
    local total = 0

    for _, p in ipairs(providers) do
        local node = p.node or p
        local a = p.available
        if a == nil and node.entity and node.entity.capabilities then
            local caps = node.entity.capabilities
            local providerCap = caps:getProvider(Resource.WATER)
            local store = caps:getStore(Resource.WATER)
            if providerCap and providerCap.enabled and store then a = store.current else a = 0 end
        end
        if a and a > 0 then
            table.insert(entries, { provider = p.provider or node, avail = a })
            total = total + a
        end
    end

    if total <= 0 then return {}, 0 end

    local remaining = amount
    local plan = {}

    for i, e in ipairs(entries) do
        if remaining <= 0 then break end
        local share
        if i == #entries then
            share = remaining
        else
            share = math.floor(amount * (e.avail / total))
        end
        share = math.min(share, e.avail, remaining)
        if share > 0 then
            plan[#plan + 1] = { provider = e.provider, amount = share }
            remaining = remaining - share
        end
    end

    return plan, (amount - remaining)
end

function Allocation.proportional_distance(providers, amount, opts)
    opts = opts or {}
    local distances = opts.distances or {}

    local entries = {}
    local totalWeight = 0

    for _, p in ipairs(providers) do
        local node = p.node or p
        local a = p.available
        if a == nil and node.entity and node.entity.capabilities then
            local caps = node.entity.capabilities
            local providerCap = caps:getProvider(Resource.WATER)
            local store = caps:getStore(Resource.WATER)
            if providerCap and providerCap.enabled and store then a = store.current else a = 0 end
        end

        local d = distances[p.provider or node]
        if a and a > 0 and d ~= nil then
            local w = 1 / math.max(d, 1)
            table.insert(entries, { provider = p.provider or node, avail = a, weight = w })
            totalWeight = totalWeight + w
        end
    end

    if totalWeight <= 0 then return {}, 0 end

    local remaining = amount
    local plan = {}

    for i, e in ipairs(entries) do
        if remaining <= 0 then break end
        local share
        if i == #entries then
            share = remaining
        else
            share = math.floor(amount * (e.weight / totalWeight))
        end
        share = math.min(share, e.avail, remaining)
        if share > 0 then
            plan[#plan + 1] = { provider = e.provider, amount = share }
            remaining = remaining - share
        end
    end

    return plan, (amount - remaining)
end

function Allocation.leveling(providers, amount)
    local ps = {}
    for i = 1, #providers do
        local p = providers[i]
        ps[i] = {
            provider = p.provider or p.node or p,
            available = p.available or 0
        }
    end

    table.sort(ps, function(a, b) return a.available > b.available end)

    local remaining = amount
    local plan = {}
    local total = 0
    for _, p in ipairs(ps) do total = total + p.available end
    if total <= 0 then return {}, 0 end

    local n = #ps
    for k = 1, n - 1 do
        if remaining <= 0 then break end
        local curr = ps[k].available
        local nextv = ps[k + 1].available
        local delta = curr - nextv
        if delta > 0 then
            local band = delta * k
            if remaining >= band then
                for i = 1, k do
                    plan[#plan + 1] = { provider = ps[i].provider, amount = delta }
                    ps[i].available = ps[i].available - delta
                end
                remaining = remaining - band
            else
                local per = math.floor(remaining / k)
                local extra = remaining % k
                for i = 1, k do
                    local take = per + (i <= extra and 1 or 0)
                    if take > 0 then
                        plan[#plan + 1] = { provider = ps[i].provider, amount = take }
                        ps[i].available = ps[i].available - take
                    end
                end
                remaining = 0
                break
            end
        end
    end

    if remaining > 0 then
        local per = math.floor(remaining / n)
        local extra = remaining % n
        for i = 1, n do
            local take = math.min(ps[i].available, per + (i <= extra and 1 or 0))
            if take > 0 then
                plan[#plan + 1] = { provider = ps[i].provider, amount = take }
                remaining = remaining - take
            end
        end
    end

    return plan, (amount - remaining)
end

return Allocation
