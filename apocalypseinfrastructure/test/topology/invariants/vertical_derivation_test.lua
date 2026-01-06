local Pipe     = require("topology/entities/Pipe")
local Registry = require("topology/net/Registry")

print("vertical_derivation_test")

-- NOTE:
-- Vertical connectivity is intentionally NOT modeled at the topology layer yet.
-- These tests assert the current invariant: topology is strictly planar.
-- Future placement/preview logic may derive vertical flow without introducing
-- node-level vertical adjacency.

local function observed()
    return {}
end

local function pos(x,y,z)
    return { x=x, y=y, z=z }
end

----------------------------------------------------------------
-- Vertical connectivity derived from adjacency + surface intent
----------------------------------------------------------------

do
    Registry.reset()

    local lower = Pipe.WaterPipe.apply{
        id = "lower",
        object = observed(),
        position = pos(10,10,0),
        attachedFaces = { north = true },
    }

    local upper = Pipe.WaterPipe.apply{
        id = "upper",
        object = observed(),
        position = pos(10,10,1),
        attachedFaces = { north = true },
    }

    lower:attach()
    upper:attach()

    -- NOTE: Vertical adjacency is not yet a topology concern.
    -- Node-level adjacency remains planar only.
    assert(lower.node.neighbors["upper"] == nil)
    assert(upper.node.neighbors["lower"] == nil)
    assert(lower.node.network ~= upper.node.network)
end

----------------------------------------------------------------
-- Removing vertical neighbor breaks vertical connectivity
----------------------------------------------------------------

do
    Registry.reset()

    local lower = Pipe.WaterPipe.apply{
        id = "lower",
        object = observed(),
        position = pos(20,20,0),
        attachedFaces = { east = true },
    }

    local upper = Pipe.WaterPipe.apply{
        id = "upper",
        object = observed(),
        position = pos(20,20,1),
        attachedFaces = { east = true },
    }

    lower:attach()
    upper:attach()

    -- No vertical adjacency at node level
    assert(lower.node.neighbors["upper"] == nil)

    upper:detach()

    assert(lower.node.neighbors["upper"] == nil)
end

----------------------------------------------------------------
-- Vertical connectivity requires matching surface intent
----------------------------------------------------------------

do
    Registry.reset()

    local lower = Pipe.WaterPipe.apply{
        id = "lower",
        object = observed(),
        position = pos(30,30,0),
        attachedFaces = { north = true },
    }

    local upper = Pipe.WaterPipe.apply{
        id = "upper",
        object = observed(),
        position = pos(30,30,1),
        attachedFaces = { east = true },
    }

    lower:attach()
    upper:attach()

    -- Different faces: no vertical derivation
    assert(lower.node.neighbors["upper"] == nil)
    assert(upper.node.neighbors["lower"] == nil)
end

print("vertical_derivation_test OK")
