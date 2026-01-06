-- placement_invariants_test.lua

local Pipe      = require("topology/entities/Pipe")
local Registry  = require("topology/net/Registry")
local Resource  = require("core/domain/Resource")
local Placement = require("topology/placement/Placement")

print("placement_invariants_test")

local function observed()
    return {}
end

local function pos(x,y,z)
    return { x=x, y=y, z=z or 0 }
end

----------------------------------------------------------------
-- PIPE PLACEMENT
----------------------------------------------------------------

do
    Registry.reset()

    local r = Placement.preview{
        entityType = "pipe",
        resource   = Resource.WATER,
        position   = pos(0,0,0),
        surface    = "floor",
    }

    assert(r.valid == true)
    assert(r.newEntity == true)
end

do
    Registry.reset()

    local p = Pipe.WaterPipe.apply{
        id = "pipe-extend-p",
        object = observed(),
        position = pos(1,1,0),
        attachedFaces = { floor = true },
    }
    p:attach()

    local r = Placement.preview{
        entityType = "pipe",
        resource   = Resource.WATER,
        position   = pos(1,1,0),
        surface    = "north",
    }

    assert(r.valid == true)
    assert(r.extendEntity == true)
end

do
    Registry.reset()

    local p = Pipe.WaterPipe.apply{
        id = "pipe-dup-p",
        object = observed(),
        position = pos(2,2,0),
        attachedFaces = { floor = true },
    }
    p:attach()

    local r = Placement.preview{
        entityType = "pipe",
        resource   = Resource.WATER,
        position   = pos(2,2,0),
        surface    = "floor",
    }

    assert(r.valid == false)
end

do
    Registry.reset()

    local p = Pipe.WaterPipe.apply{
        id = "pipe-cross-resource-p",
        object = observed(),
        position = pos(3,3,0),
        attachedFaces = { floor = true },
    }
    p:attach()

    local r = Placement.preview{
        entityType = "pipe",
        resource   = Resource.FUEL,
        position   = pos(3,3,0),
        surface    = "floor",
    }

    assert(r.valid == true)
end

----------------------------------------------------------------
-- VALVE PLACEMENT
----------------------------------------------------------------

do
    Registry.reset()

    local a = Pipe.WaterPipe.apply{
        id = "valve-two-a",
        object = observed(),
        position = pos(10,0,0),
        attachedFaces = { floor = true },
    }
    local b = Pipe.WaterPipe.apply{
        id = "valve-two-b",
        object = observed(),
        position = pos(12,0,0),
        attachedFaces = { floor = true },
    }
    a:attach()
    b:attach()

    local r = Placement.preview{
        entityType = "valve",
        resource   = Resource.WATER,
        position   = pos(11,0,0),
        surface    = "floor",
    }

    assert(r.valid == true)
    assert(#r.connections == 2)
end

do
    Registry.reset()

    local a = Pipe.WaterPipe.apply{
        id = "valve-few-a",
        object = observed(),
        position = pos(20,0,0),
        attachedFaces = { floor = true },
    }
    a:attach()

    local r = Placement.preview{
        entityType = "valve",
        resource   = Resource.WATER,
        position   = pos(21,0,0),
        surface    = "floor",
    }

    assert(r.valid == false)
end

do
    Registry.reset()

    local a = Pipe.WaterPipe.apply{
        id = "valve-many-a",
        object = observed(),
        position = pos(30,0,0),
        attachedFaces = { floor = true },
    }
    local b = Pipe.WaterPipe.apply{
        id = "valve-many-b",
        object = observed(),
        position = pos(32,0,0),
        attachedFaces = { floor = true },
    }
    local c = Pipe.WaterPipe.apply{
        id = "valve-many-c",
        object = observed(),
        position = pos(31,1,0),
        attachedFaces = { floor = true },
    }
    a:attach()
    b:attach()
    c:attach()

    local r = Placement.preview{
        entityType = "valve",
        resource   = Resource.WATER,
        position   = pos(31,0,0),
        surface    = "floor",
    }

    assert(r.valid == false)
end

----------------------------------------------------------------
-- VALVE PLACEMENT (corner and wall cases)
----------------------------------------------------------------

do
    Registry.reset()

    -- Corner valve on floor (north + east)
    local n = Pipe.WaterPipe.apply{
        id = "corner-n",
        object = observed(),
        position = pos(50,49,0),
        attachedFaces = { floor = true },
    }
    local e = Pipe.WaterPipe.apply{
        id = "corner-e",
        object = observed(),
        position = pos(51,50,0),
        attachedFaces = { floor = true },
    }
    n:attach()
    e:attach()

    local r = Placement.preview{
        entityType = "valve",
        resource   = Resource.WATER,
        position   = pos(50,50,0),
        surface    = "floor",
    }

    assert(r.valid == true)
    assert(#r.connections == 2)
    assert(r.straight == false)
end

do
    Registry.reset()

    -- Straight valve on a wall surface: neighbors on opposite sides, empty middle
    local w = Pipe.WaterPipe.apply{
        id = "wall-straight-w",
        object = observed(),
        position = pos(59,60,0),
        attachedFaces = { north = true },
    }
    local e = Pipe.WaterPipe.apply{
        id = "wall-straight-e",
        object = observed(),
        position = pos(61,60,0),
        attachedFaces = { north = true },
    }
    w:attach()
    e:attach()

    local r = Placement.preview{
        entityType = "valve",
        resource   = Resource.WATER,
        position   = pos(60,60,0),
        surface    = "north",
    }

    assert(r.valid == true)
    assert(r.straight == true)
end

do
    Registry.reset()

    -- Invalid wall valve: only one connection on that wall surface
    local w = Pipe.WaterPipe.apply{
        id = "wall-invalid-w",
        object = observed(),
        position = pos(70,70,0),
        attachedFaces = { east = true },
    }
    w:attach()

    local r = Placement.preview{
        entityType = "valve",
        resource   = Resource.WATER,
        position   = pos(70,70,0),
        surface    = "east",
    }

    assert(r.valid == false)
end

----------------------------------------------------------------
-- RESOURCE ISOLATION
----------------------------------------------------------------

do
    Registry.reset()

    local a = Pipe.WaterPipe.apply{
        id = "res-iso-water",
        object = observed(),
        position = pos(40,0,0),
        attachedFaces = { floor = true },
    }
    local b = Pipe.FuelPipe.apply{
        id = "res-iso-fuel",
        object = observed(),
        position = pos(42,0,0),
        attachedFaces = { floor = true },
    }
    a:attach()
    b:attach()

    local r = Placement.preview{
        entityType = "valve",
        resource   = Resource.WATER,
        position   = pos(41,0,0),
        surface    = "floor",
    }

    assert(r.valid == false)
end

----------------------------------------------------------------
-- WALL SURFACE RESOURCE ISOLATION
----------------------------------------------------------------

do
    Registry.reset()

    local fuel = Pipe.FuelPipe.apply{
        id = "wall-iso-fuel",
        object = observed(),
        position = pos(91,90,0),
        attachedFaces = { west = true },
    }
    fuel:attach()

    local r = Placement.preview{
        entityType = "valve",
        resource   = Resource.WATER,
        position   = pos(92,90,0),
        surface    = "west",
    }

    assert(r.valid == false)
end

----------------------------------------------------------------
-- COMMIT PLACEMENT
----------------------------------------------------------------

do
    Registry.reset()

    -- Commit new pipe
    local preview = Placement.preview{
        entityType = "pipe",
        resource   = Resource.WATER,
        position   = pos(100,100,0),
        surface    = "floor",
    }

    assert(preview.valid == true)

    local e = Placement.commit{
        preview  = preview,
        id       = "commit-new-pipe",
        observed = observed(),
        position = pos(100,100,0),
        resource = Resource.WATER,
    }

    assert(e ~= nil)
    assert(e.attached == true)
    assert(e.attachedFaces.floor == true)
end

do
    Registry.reset()

    -- Commit pipe extension
    local p = Pipe.WaterPipe.apply{
        id = "commit-base-pipe",
        object = observed(),
        position = pos(101,101,0),
        attachedFaces = { floor = true },
    }
    p:attach()

    local preview = Placement.preview{
        entityType = "pipe",
        resource   = Resource.WATER,
        position   = pos(101,101,0),
        surface    = "north",
    }

    assert(preview.valid == true)
    assert(preview.extendEntity == true)

    local e = Placement.commit{
        preview  = preview,
        id       = "ignored",
        observed = observed(),
        position = pos(101,101,0),
        resource = Resource.WATER,
    }

    assert(e == p)
    assert(p.attachedFaces.north == true)
end

do
    Registry.reset()

    -- Commit valve
    local a = Pipe.WaterPipe.apply{
        id = "commit-valve-a",
        object = observed(),
        position = pos(110,100,0),
        attachedFaces = { floor = true },
    }
    local b = Pipe.WaterPipe.apply{
        id = "commit-valve-b",
        object = observed(),
        position = pos(112,100,0),
        attachedFaces = { floor = true },
    }
    a:attach()
    b:attach()

    local preview = Placement.preview{
        entityType = "valve",
        resource   = Resource.WATER,
        position   = pos(111,100,0),
        surface    = "floor",
    }

    assert(preview.valid == true)

    local v = Placement.commit{
        preview  = preview,
        id       = "commit-valve",
        observed = observed(),
        position = pos(111,100,0),
        resource = Resource.WATER,
    }

    assert(v ~= nil)
    assert(v.attached == true)
end

do
    Registry.reset()

    -- Commit must reject invalid preview
    local bad = { valid = false }
    local ok = pcall(function()
        Placement.commit{
            preview  = bad,
            id       = "bad-commit",
            observed = observed(),
            position = pos(200,200,0),
            resource = Resource.WATER,
        }
    end)

    assert(ok == false)
end

print("placement_invariants_test OK")
