-- PlanApplicationResult.lua
-- Result object for applying a resource plan.
-- Lua 5.1 compatible. Pure value object.

local PlanApplicationResult = {}
PlanApplicationResult.__index = PlanApplicationResult

function PlanApplicationResult.new(requested)
    return setmetatable({
        requested = requested,
        applied = 0,
        failures = {}
    }, PlanApplicationResult)
end

function PlanApplicationResult:recordSuccess(amount)
    self.applied = self.applied + amount
end

function PlanApplicationResult:recordFailure(provider, reason)
    table.insert(self.failures, {
        provider = provider,
        reason = reason
    })
end

function PlanApplicationResult:isOk()
    return self.applied > 0
end

return PlanApplicationResult
