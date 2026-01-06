-- Minimal Project Zomboid stubs for local testing
-- DO NOT add behavior here unless strictly required.

Events = {
  OnGameStart = {
    Add = function(fn)
      -- Immediately invoke for local tests
      fn()
    end
  }
}

-- Dummy instanceof check
function instanceof(obj, className)
  return obj and obj.__class == className
end

-- Dummy logger
Runtime = {
  Logger = {
    debug = function(msg) print("[DEBUG]", msg) end,
    error = function(msg) print("[ERROR]", msg) end,
  },
  Settings = {
    devEnabled = true
  }
}
