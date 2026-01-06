-- Placement.lua
--
-- Pure placement preview and validation logic.
--
-- Placement is READ‑ONLY:
--   • Never mutates topology
--   • Never mutates entities
--   • Never registers or unregisters nodes
--   • Returns structured preview results only
--
-- This module answers:
--   • Can I place this entity here?
--   • If so, what surface intent and connections would result?
--
-- Placement rules are enforced here, not in Entity/Pipe/Valve.

local Registry = require("topology/net/Registry")
local Resource = require("core/domain/Resource")

local Placement = {}

----------------------------------------------------------------
-- Result helpers
----------------------------------------------------------------

local function valid(result)
    result.valid = true
    return result
end

local function invalid(reason)
    return {
        valid  = false,
        reason = reason,
    }
end

----------------------------------------------------------------
-- Surface helpers
----------------------------------------------------------------

local SURFACES = {
    "floor",
    "north",
    "east",
    "south",
    "west",
}

local function surfaceIsValid(surface)
    for _, s in ipairs(SURFACES) do
        if s == surface then return true end
    end
    return false
end

----------------------------------------------------------------
-- Adjacency helpers (planar only)
----------------------------------------------------------------

local CARDINAL = {
    north = { dx =  0, dy = -1 },
    east  = { dx =  1, dy =  0 },
    south = { dx =  0, dy =  1 },
    west  = { dx = -1, dy =  0 },
}

local function opposite(dir)
    if dir == "north" then return "south" end
    if dir == "south" then return "north" end
    if dir == "east"  then return "west"  end
    if dir == "west"  then return "east"  end
end

----------------------------------------------------------------
-- Collect connectable neighbors on a given surface
----------------------------------------------------------------

local function collectSurfaceAdjacency(opts)
    local resource = opts.resource
    local surface  = opts.surface
    local pos      = opts.position

    local neighbors = {}

    for dir, o in pairs(CARDINAL) do
        local nx = pos.x + o.dx
        local ny = pos.y + o.dy
        local nz = pos.z

        local node = Registry.getNodeAtPosition(nx, ny, nz)
        if node and node.topologyResource == resource then
            local entity = node.entity
            if entity and entity.attachedFaces and entity.attachedFaces[surface] then
                table.insert(neighbors, {
                    direction = dir,
                    node      = node,
                })
            end
        end
    end

    return neighbors
end

----------------------------------------------------------------
-- Pipe placement preview
----------------------------------------------------------------

local function previewPipe(opts)
    if not surfaceIsValid(opts.surface) then
        return invalid("invalid surface")
    end

    local resource = opts.resource
    local pos      = opts.position

    -- Entity already exists at this cell for this resource?
    local existing = Registry.getNodeAtPosition(pos.x, pos.y, pos.z)
    if existing and existing.topologyResource == resource then
        local entity = existing.entity
        if entity.attachedFaces and entity.attachedFaces[opts.surface] then
            return invalid("surface already occupied")
        end

        -- Valid: extend intent on existing entity
        return valid({
            entityType   = "pipe",
            surface      = opts.surface,
            extendEntity = true,
        })
    end

    -- No entity yet for this resource in this cell
    return valid({
        entityType = "pipe",
        surface    = opts.surface,
        newEntity  = true,
    })
end

----------------------------------------------------------------
-- Valve placement preview
----------------------------------------------------------------

local function previewValve(opts)
    if not surfaceIsValid(opts.surface) then
        return invalid("invalid surface")
    end

    local resource = opts.resource
    local pos      = opts.position

    -- Only one entity per cell per resource
    local existing = Registry.getNodeAtPosition(pos.x, pos.y, pos.z)
    if existing and existing.topologyResource == resource then
        return invalid("cell already occupied for resource")
    end

    -- Find connectable attachments on the chosen surface
    local neighbors = collectSurfaceAdjacency(opts)

    if #neighbors < 2 then
        return invalid("valve requires exactly two connections")
    end

    if #neighbors > 2 then
        return invalid("valve cannot gate more than two connections")
    end

    local a = neighbors[1].direction
    local b = neighbors[2].direction

    -- Compute whether this is a straight or corner valve (informational only)
    local straight = (opposite(a) == b)

    return valid({
        entityType  = "valve",
        surface     = opts.surface,
        connections = { a, b },
        straight    = straight,
    })
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

-- opts:
--   • entityType: "pipe" | "valve"
--   • resource
--   • position {x,y,z}
--   • surface
function Placement.preview(opts)
    assert(opts)
    assert(opts.entityType)
    assert(opts.resource)
    assert(opts.position)
    assert(opts.surface)

    if opts.entityType == "pipe" then
        return previewPipe(opts)
    end

    if opts.entityType == "valve" then
        return previewValve(opts)
    end

    return invalid("unknown entity type")
end

-- Commit placement
-- Turns a VALID preview into concrete entity creation + attach.
-- Preview must already have enforced all invariants.

local Pipe  = require("topology/entities/Pipe")
local Valve = require("topology/entities/Valve")

local function pipeConstructorFor(resource)
    if resource == Resource.WATER then return Pipe.WaterPipe end
    if resource == Resource.FUEL then return Pipe.FuelPipe end
    if resource == Resource.PROPANE then return Pipe.PropanePipe end
    if resource == Resource.ELECTRICITY then return Pipe.ElectricPipe end
    error("No Pipe constructor for resource: " .. tostring(resource))
end

local function valveConstructorFor(resource)
    if resource == Resource.WATER then return Valve.WaterValve end
    if resource == Resource.FUEL then return Valve.FuelValve end
    if resource == Resource.PROPANE then return Valve.PropaneValve end
    if resource == Resource.ELECTRICITY then return Valve.ElectricValve end
    error("No Valve constructor for resource: " .. tostring(resource))
end

function Placement.commit(opts)
    assert(opts and opts.preview and opts.preview.valid == true,
        "Placement.commit requires a valid preview")

    local preview  = opts.preview
    local resource = opts.resource
    local position = opts.position
    local observed = opts.observed
    local id       = opts.id

    assert(resource and position and observed and id,
        "commit requires id, resource, position, and observed")

    -- PIPE
    if preview.entityType == "pipe" then
        -- Extend existing entity
        if preview.extendEntity then
            local node = Registry.getNodeAtPosition(
                position.x, position.y, position.z
            )
            assert(node and node.entity,
                "expected existing entity when extending pipe")

            node.entity.attachedFaces[preview.surface] = true
            node.entity:recomputeFaceConnectivity()
            return node.entity
        end

        -- Create new pipe
        local pipe = pipeConstructorFor(resource).apply{
            id = id,
            object = observed,
            position = position,
            attachedFaces = { [preview.surface] = true },
        }
        pipe:attach()
        return pipe
    end

    -- VALVE
    if preview.entityType == "valve" then
        local valve = valveConstructorFor(resource).apply{
            id = id,
            object = observed,
            position = position,
            attachedFaces = { [preview.surface] = true },
            connections = preview.connections,
        }
        valve:attach()
        return valve
    end

    error("Unknown entityType in Placement.commit")
end

return Placement
