local Registry   = require("topology/net/Registry")
local Node       = require("topology/net/Node")
local Resource   = require("core/domain/Resource")
local Capability = require("core/domain/Capability")

local Capabilities = Capability.Capabilities

print("registry_test")

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function newEntity(id)
    return {
        id = id,
        capabilities = Capabilities.new(),
    }
end

local function newNode(id, topo, x, y, z)
    return Node.new(
        id,
        topo,
        { x = x, y = y, z = z or 0 },
        newEntity("entity-" .. id)
    )
end

----------------------------------------------------------------
-- Test: Registry.reset clears all indexes
----------------------------------------------------------------

do
    Registry.reset()

    assert(next(Registry.nodesById) == nil)
    assert(next(Registry.nodesByPos) == nil)
    assert(next(Registry.nodesByPosAndResource) == nil)
end

----------------------------------------------------------------
-- Test: registerNode indexes by id and position
----------------------------------------------------------------

do
    Registry.reset()

    local n = newNode("n1", Resource.WATER, 10, 20, 0)
    Registry.registerNode(n)

    assert(Registry.nodesById["n1"] == n)

    local key = "10:20:0"
    assert(Registry.nodesByPos[key] ~= nil)
    assert(Registry.nodesByPos[key]["n1"] == n)

    local bucket = Registry.getNodesAtPosition(10, 20, 0, Resource.WATER)
    assert(bucket ~= nil)
    assert(bucket["n1"] == n)

    assert(Registry.hasConnectorAt(10, 20, 0, Resource.WATER) == true)
end

----------------------------------------------------------------
-- Test: cardinal adjacency connects nodes (E/W)
----------------------------------------------------------------

do
    Registry.reset()

    local a = newNode("a", Resource.WATER, 0, 0, 0)
    local b = newNode("b", Resource.WATER, 1, 0, 0) -- east of a

    Registry.registerNode(a)
    Registry.registerNode(b)

    assert(a.neighbors["b"] ~= nil)
    assert(b.neighbors["a"] ~= nil)

    assert(a.network ~= nil)
    assert(b.network ~= nil)
    assert(a.network == b.network)
end

----------------------------------------------------------------
-- Test: cardinal adjacency connects nodes (N/S)
----------------------------------------------------------------

do
    Registry.reset()

    local a = newNode("a", Resource.WATER, 0, 0, 0)
    local b = newNode("b", Resource.WATER, 0, 1, 0) -- south of a

    Registry.registerNode(a)
    Registry.registerNode(b)

    assert(a.neighbors["b"] ~= nil)
    assert(b.neighbors["a"] ~= nil)
    assert(a.network == b.network)
end

----------------------------------------------------------------
-- Test: diagonal adjacency does NOT connect
----------------------------------------------------------------

do
    Registry.reset()

    local a = newNode("a", Resource.WATER, 0, 0, 0)
    local b = newNode("b", Resource.WATER, 1, 1, 0) -- diagonal

    Registry.registerNode(a)
    Registry.registerNode(b)

    assert(a.neighbors["b"] == nil)
    assert(b.neighbors["a"] == nil)
    assert(a.network ~= b.network)
end

----------------------------------------------------------------
-- Test: different topologyResource does NOT connect even if adjacent
----------------------------------------------------------------

do
    Registry.reset()

    local w = newNode("w", Resource.WATER, 0, 0, 0)
    local f = newNode("f", Resource.FUEL,  1, 0, 0)

    Registry.registerNode(w)
    Registry.registerNode(f)

    assert(w.neighbors["f"] == nil)
    assert(f.neighbors["w"] == nil)
    assert(w.network ~= f.network)
end

----------------------------------------------------------------
-- Test: duplicate same-tile placement for same topologyResource is rejected
----------------------------------------------------------------

do
    Registry.reset()

    local a = newNode("a", Resource.WATER, 2, 2, 0)
    local b = newNode("b", Resource.WATER, 2, 2, 0)

    Registry.registerNode(a)

    local ok = pcall(function()
        Registry.registerNode(b)
    end)

    assert(ok == false)
end

----------------------------------------------------------------
-- Test: unregisterNode cleans neighbors and splits network
----------------------------------------------------------------

do
    Registry.reset()

    -- a -- b -- c (horizontal line)
    local a = newNode("a", Resource.WATER, 0, 5, 0)
    local b = newNode("b", Resource.WATER, 1, 5, 0)
    local c = newNode("c", Resource.WATER, 2, 5, 0)

    Registry.registerNode(a)
    Registry.registerNode(b)
    Registry.registerNode(c)

    assert(a.network == b.network and b.network == c.network)

    Registry.unregisterNode(b)

    assert(a.network ~= nil)
    assert(c.network ~= nil)
    assert(a.network ~= c.network)

    assert(a.neighbors["b"] == nil)
    assert(c.neighbors["b"] == nil)
end

----------------------------------------------------------------
-- Test: Z-level isolation
----------------------------------------------------------------

do
    Registry.reset()

    local a = newNode("a", Resource.WATER, 0, 0, 0)
    local b = newNode("b", Resource.WATER, 0, 0, 1)

    Registry.registerNode(a)
    Registry.registerNode(b)

    assert(a.neighbors["b"] == nil)
    assert(a.network ~= b.network)
end

----------------------------------------------------------------
-- Test: Registry adjacency is strictly planar (no vertical adjacency)
-- (already tested by Z-level isolation, but we also assert no neighbor links)
----------------------------------------------------------------

do
    Registry.reset()

    local a = newNode("pz0", Resource.WATER, 9, 9, 0)
    local b = newNode("pz1", Resource.WATER, 9, 9, 1)

    Registry.registerNode(a)
    Registry.registerNode(b)

    assert(a.neighbors["pz1"] == nil)
    assert(b.neighbors["pz0"] == nil)
    assert(a.network ~= b.network)
end

----------------------------------------------------------------
-- Test: Registry does not connect through missing intermediate nodes
-- a(0,0) and c(2,0) do NOT connect without b(1,0)
----------------------------------------------------------------

do
    Registry.reset()

    local a = newNode("gap-a", Resource.WATER, 0, 0, 0)
    local c = newNode("gap-c", Resource.WATER, 2, 0, 0)

    Registry.registerNode(a)
    Registry.registerNode(c)

    assert(a.neighbors["gap-c"] == nil)
    assert(c.neighbors["gap-a"] == nil)
    assert(a.network ~= c.network)
end

----------------------------------------------------------------
-- Test: Attach order does not matter (merge when middle arrives)
-- Register endpoints first, then middle; then remove middle splits.
----------------------------------------------------------------

do
    Registry.reset()

    local a = newNode("ord-a", Resource.WATER, 0, 7, 0)
    local b = newNode("ord-b", Resource.WATER, 1, 7, 0)
    local c = newNode("ord-c", Resource.WATER, 2, 7, 0)

    -- endpoints first
    Registry.registerNode(a)
    Registry.registerNode(c)

    assert(a.network ~= c.network)

    -- add middle
    Registry.registerNode(b)

    assert(a.network == b.network)
    assert(b.network == c.network)

    -- remove middle splits
    Registry.unregisterNode(b)

    assert(a.network ~= nil)
    assert(c.network ~= nil)
    assert(a.network ~= c.network)
end

print("registry_test OK")
