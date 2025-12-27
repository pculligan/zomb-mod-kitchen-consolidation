-- Engine.lua
-- Convenience aggregation module for KitchenConsolidation Zomboid-domain helpers.
-- This file intentionally contains *no logic* of its own.
-- It exists only to centralize requires so callers can depend on a single entry point.

local Engine = {}

-- Core identity wrapper (read-only)
Engine.Item = require "Engine/Item"

-- Food helpers (engine-native semantics)
Engine.ItemFood = require "Engine/ItemFood"

-- Weight helpers (mirrors working mod patterns, e.g. SapphCooking)
Engine.ItemWeight = require "Engine/ItemWeight"

-- Inventory / container helpers
Engine.Inventory = require "Engine/Inventory"

return Engine
