-- Optional.lua
-- A small, explicit Optional type with instance methods

local Optional = {}
Optional.__index = Optional

-- ==========
-- Constructor
-- ==========

function Optional.new(has, value)
    local self = {
        _isOptional = true,
        has = has == true,
        value = value
    }
    return setmetatable(self, Optional)
end

-- ==========
-- Static helpers (factory-style)
-- ==========

function Optional.some(value)
    return Optional.new(true, value)
end

function Optional.none()
    return Optional.new(false, nil)
end

function Optional.fromNullable(value)
    if value == nil then
        return Optional.none()
    end
    return Optional.some(value)
end

function Optional.of(value)
    return Optional.fromNullable(value)
end

function Optional.isOptional(o)
    return type(o) == "table" and getmetatable(o) == Optional
end

-- ==========
-- Instance methods
-- ==========

function Optional:isSome()
    return self.has == true
end

function Optional:isNone()
    return self.has ~= true
end

function Optional:unwrap(context)
    if not Optional.isOptional(self) then
        error("Optional.unwrap called on non-Optional value in " .. tostring(context))
    end
    if not self.has then
        error("Tried to unwrap Optional.none in " .. tostring(context))
    end
    return self.value
end

function Optional:unwrapOr(default)
    if self.has then
        return self.value
    end
    return default
end

function Optional:map(fn)
    if not self.has then
        return self
    end
    return Optional.some(fn(self.value))
end

function Optional:debug()
    if self.has then
        return "Some(" .. tostring(self.value) .. ")"
    end
    return "None"
end

-- ==========
-- Backwards-compatible functional wrappers
-- (so existing call sites don't break)
-- ==========

function Optional.unwrap(o, context)
    return Optional.unwrap(o, context)
end

function Optional.unwrapOr(o, default)
    if Optional.isOptional(o) then
        return o:unwrapOr(default)
    end
    return default
end

function Optional.debug(o)
    if Optional.isOptional(o) then
        return o:debug()
    end
    return "<not optional>"
end

return Optional