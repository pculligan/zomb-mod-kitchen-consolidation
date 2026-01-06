local M = {}

function M.eq(actual, expected, msg)
  if actual ~= expected then
    error((msg or "assert.eq failed") ..
      ": expected=" .. tostring(expected) ..
      " actual=" .. tostring(actual))
  end
end

function M.truthy(val, msg)
  if not val then
    error(msg or "assert.truthy failed")
  end
end

function M.falsy(val, msg)
  if val then
    error(msg or "assert.falsy failed")
  end
end

return M
