local Runtime = require("infra/Runtime")

local assured = Runtime.Guard.assured
local failOn = Runtime.Guard.failOn
local warnOn = Runtime.Guard.warnOn


local debug = Runtime.Logger.debug
local trace = Runtime.Logger.trace

-- Standalone FoodRegistry
-- This object owns the registry map and exposes instance methods only.
local FoodRegistry = {}
FoodRegistry.__index = FoodRegistry

-- Singleton instance (eagerly initialized)
FoodRegistry.instance = nil

-- Constructor
function FoodRegistry.new()
    local self = {
        _registry = {}
    }
    setmetatable(self, FoodRegistry)
    return self
end

-- Register a single FoodType
function FoodRegistry:register(foodType)
    if failOn(not foodType or type(foodType) ~= "table" or not foodType.fullType,
              "FoodRegistry:register called with invalid FoodType: " .. tostring(foodType)) then return end

    -- Registry is declarative only: no engine probing, no temp items

    -- Ensure required logical fields exist
    assured(foodType.fullType, "FoodRegistry: FoodType missing fullType")

    -- maxHunger may be provided later via engine layer; do not derive here
    if not foodType.maxHunger then
        trace("FoodRegistry: maxHunger not set for " .. foodType.fullType .. " (allowed)")
    end

    -- weightFull / weightEmpty are runtime concerns; do not derive here
    if foodType.weightFull then
        debug("FoodRegistry: weightFull pre-set for " .. foodType.fullType .. " = " .. tostring(foodType.weightFull))
    end
    if foodType.weightEmpty then
        debug("FoodRegistry: weightEmpty pre-set for " .. foodType.fullType .. " = " .. tostring(foodType.weightEmpty))
    end

    self._registry[foodType.fullType] = foodType
    debug(
        string.format(
            "FoodRegistry: REGISTERED %s | maxHunger=%s | weightFull=%s | weightEmpty=%s | containerized=%s | prepTo=%s",
            foodType.fullType,
            tostring(foodType.maxHunger),
            tostring(foodType.weightFull),
            tostring(foodType.weightEmpty),
            tostring(foodType.isContainerized),
            tostring(foodType.prepTo)
        )
    )
end

-- Register a list of FoodTypes
function FoodRegistry:registerAll(list)
    if failOn(type(list) ~= "table" or #list == 0,
              "FoodRegistry:registerAll requires non-empty table") then return end

    for _, foodType in ipairs(list) do
        self:register(foodType)
    end
end

-- Retrieve a FoodType by fullType
function FoodRegistry:get(fullType)
    if warnOn(not fullType, "FoodRegistry:get called with nil fullType") then return nil end
    return self._registry[fullType]
end

-- Check existence of a FoodType by fullType
function FoodRegistry:has(fullType)
    if warnOn(not fullType, "FoodRegistry:has called with nil fullType") then return false end
    return self._registry[fullType] ~= nil
end

function FoodRegistry:all()
    return self._registry
end

-- Debug dump of all registered FoodTypes
function FoodRegistry:debugDump()
    debug("FoodRegistry: debugDump BEGIN")

    local keys = {}
    for k, _ in pairs(self._registry) do
        table.insert(keys, k)
    end
    table.sort(keys)

    for _, fullType in ipairs(keys) do
        local ft = self._registry[fullType]
        if ft then
            debug(
                string.format(
                    "FoodRegistry: FoodType %s | maxHunger=%s | weightFull=%s | weightEmpty=%s | containerized=%s | prepTo=%s | byproducts=%s",
                    tostring(ft.fullType),
                    tostring(ft.maxHunger),
                    tostring(ft.weightFull),
                    tostring(ft.weightEmpty),
                    tostring(ft.isContainerized),
                    tostring(ft.prepTo),
                    tostring(ft.byproductsOnEmpty)
                )
            )
        end
    end

    debug("FoodRegistry: debugDump END")
end

-- Eagerly initialize the singleton instance
if not FoodRegistry.instance then
    FoodRegistry.instance = FoodRegistry.new()
    debug("FoodRegistry: singleton instance initialized")
end

return FoodRegistry