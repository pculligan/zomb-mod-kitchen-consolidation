-- Runtime.lua
-- Singleton runtime context for Apocalypse Infrastructure.
--
-- This module centralizes shared runtime utilities (Logger, Guard, Optional)
-- and ensures they are instantiated exactly once with consistent configuration.
--
-- Usage:
--   local RT = require("runtime.Runtime")
--   RT.Logger.debug("hello")
--   RT.Guard.failOn(x == nil, "x must not be nil")

-- ---------------------------------------------------------------------------
-- Load configuration
-- ---------------------------------------------------------------------------

local Settings = require("settings/Settings")

-- ---------------------------------------------------------------------------
-- Instantiate Logger (singleton)
-- ---------------------------------------------------------------------------

local LoggerFactory = require("infra/Logger")
local Logger = LoggerFactory.new(Settings.name, Settings.logLevel)

-- ---------------------------------------------------------------------------
-- Instantiate Guard (singleton, bound to Logger)
-- ---------------------------------------------------------------------------

local GuardFactory = require("infra/Guard")
local Guard = GuardFactory.new(Logger)

-- ---------------------------------------------------------------------------
-- Optional utilities (stateless)
-- ---------------------------------------------------------------------------

local Optional = require("infra/Optional")

-- ---------------------------------------------------------------------------
-- Singleton export
-- ---------------------------------------------------------------------------

local Runtime = {
    Logger   = Logger,
    Guard    = Guard,
    Optional = Optional,
    Settings = Settings
}

----------------------------------------------------------------
-- Global registration (PZ shared-loader compatibility)
----------------------------------------------------------------

_G.ApocInfra = _G.ApocInfra or {}
_G.ApocInfra.Runtime = Runtime

return Runtime
