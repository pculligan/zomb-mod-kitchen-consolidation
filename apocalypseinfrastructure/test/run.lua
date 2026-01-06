-- Lua 5.1 test runner
assert(_VERSION == "Lua 5.1", "Tests must run under Lua 5.1 semantics")

-- Adjust package path to load project code
package.path = package.path
  .. ";./media/lua//?.lua"
  .. ";./media/lua/shared/?.lua"
  .. ";./media/lua/server/?.lua"
  .. ";./media/lua//?/init.lua"
  .. ";./test/?.lua"
  .. ";./test/stubs/?.lua"
  .. ";./test/helpers/?.lua"

require("stubs/pz")

print("Running Apocalypse Infrastructure tests...\n")



require("core/domain/resource_test")
require("core/domain/allocation_test")
require("core/domain/capability_constructors_test")
require("core/domain/capability_ordering_test")

require("core/traits/storage_trait_test")
require("core/traits/provider_trait_test")
require("core/traits/consumer_trait_test")

-- Topology primitives
require("topology/net/node_test")
require("topology/net/network_test")
require("topology/net/registry_test")

-- Entity foundations
require("topology/entities/base_entity_test")
require("topology/entities/pipe_entity_test")
require("topology/entities/valve_entity_test")

-- Cross-cutting topology invariants
require("topology/invariants/surface_invariants_test")
require("topology/invariants/vertical_derivation_test")
require("topology/invariants/topology_resource_isolation_test")

-- Placement rules (depends on full topology)
require("topology/placement/placement_invariants_test")

-- Flow / integration tests (depend on everything above)
require("flows/flow_scenarios_test")

print("\nAll tests completed.")
