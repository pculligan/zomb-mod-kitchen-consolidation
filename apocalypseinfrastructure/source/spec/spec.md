# Drip Irrigation & Resource Network System — Design Specification


## 1. Core Model

### 1.1 Node Model & Indexing

This section defines how nodes are represented, identified, and efficiently located.
Correct node modeling and indexing are critical to enforcing locality and O(1) neighbor lookup.

#### Node Definition

A **node** is a world object that participates in a resource network.
Each node represents exactly one physical object placed in the world.

Each node must have:
- A stable world position (x, y, z)
- Zero or more resource capabilities (e.g., provide, consume, store)
- Or no capabilities (transport-only nodes)
- A reference to its underlying world object (IsoObject or equivalent)
- A reference to the network it currently belongs to (derived)

Node behavior is determined by the capabilities it advertises, not by fixed roles.

Nodes do not own network state.
They contribute local facts only.


#### Node Identity

Node identity is defined by:
- World position
- Object identity within that square (if multiple nodes may coexist)

Node identity:
- Must be stable across save/load
- Must be reconstructible on chunk load
- Must not rely on transient Lua object references
- Must not be derived from network identity


#### Indexing Strategy

Nodes must be indexed to allow constant-time lookup by position.

At minimum, the system must provide:
- A global index keyed by world position
- Efficient retrieval of all nodes occupying a given square

Indexing guarantees:
- Neighbor lookup is O(1)
- Registration cost is bounded by local adjacency
- No full-network or full-world scans are required

The indexing structure is an implementation detail, but linear scans over nodes are explicitly forbidden.


#### Neighbor Discovery

When a node registers or deregisters:
- Only orthogonally adjacent squares (N/E/S/W) are queried
- Nodes in those squares are retrieved via the index
- Connectivity rules are evaluated pairwise

Neighbor discovery must:
- Be symmetric
- Be deterministic
- Avoid side effects beyond network merge/split decisions


#### Persistence Considerations

Node indexing structures:
- May be rebuilt on server start
- Must be reconstructed on chunk load
- Must not require persistence of the index itself

Persistent storage should favor:
- Node-local state
- World object modData where appropriate

Derived structures such as indexes and network membership must remain ephemeral.


#### Performance Guarantees

The node model and indexing strategy must guarantee:
- O(1) neighbor lookup
- O(k) registration cost, where k is the number of adjacent nodes
- No background or periodic maintenance cost
- Predictable behavior as node count increases


## 2. Connectors & Explicit Connection Semantics

This system uses **explicit connector objects** to represent intentional connections between world objects and resource networks.
Connectors are first-class nodes in the network; underlying world objects are observed, not owned.

Connection is represented by **placement of a connector**, not by proximity checks or attach actions.


### Connector Role

A **connector** is a placeable object that:
- Represents explicit player intent to connect a world object to a network
- Acts as the network-facing node and advertises resource capabilities
- Observes the state of an underlying world object
- Mediates policy and compatibility between the object and the network

The underlying object (e.g., rain barrel, generator, crop, house) is **not** itself a network node.


### Connector Types

Connector behavior is defined by the resource-specific capabilities it advertises
(e.g., provide, consume, store), as described in the Connector Manifest.


### Explicit Placement Semantics

Connections are created and destroyed **only** through connector placement or removal.

- Being adjacent to a source or sink is not sufficient to establish connectivity
- Placing a connector represents all necessary plumbing, attachment, or interfacing work
- Connector placement may require tools, time, or materials
- Removing a connector cleanly severs the connection

No additional "attach", "plumb", or proximity-based actions are required.

Some connectors may enforce spatial placement constraints
(e.g., minimum distance between similar connectors),
evaluated only at placement time.


### Resource Typing & Compatibility

Connectors and transport elements are **resource-typed**.

- Water transport elements connect only to water connectors
- Fuel transport elements connect only to fuel connectors
- Propane transport elements connect only to propane connectors
- No resource mixing is permitted

Multiple connectors and transport elements of different resource types may coexist on the same world square.

Compatibility rules are enforced at placement time and during registration.

- Pumpable Water is a distinct resource representing water that exists but cannot be used without pumping
- Pumpable Water may be transformed into Water only via a Pump connector


### Resource Type Definitions (Authoritative)

The system models three resource types. Resource type determines:
- Which transport elements may connect
- Which connectors may provide or consume
- Which semantics (quality, dominance) apply

#### Water

**Water** is usable water intended for consumption by sinks (drinking, irrigation, washing, fixtures).
- May be **provided** by connectors (e.g., barrels, pumps, tanker drain mode)
- May be **consumed** by connectors (e.g., drip irrigation, house fixtures)
- May be **stored** by connectors that observe world objects with volume

Water is the only resource type that participates in **Water Quality & Potability Semantics**
(i.e., `potable`, `tainted`, `toxic`) and the associated dominance rule.

#### Pumpable Water

**Pumpable Water** represents water that exists in the world but is not directly usable without pumping
(e.g., rivers, lakes, wells, below-grade intakes). It encodes “pressure/elevation required” without simulation.

Rules:
- Pumpable Water MUST NOT be consumed by normal sinks (drinking, irrigation, fixtures).
- Pumpable Water is consumed only by pump connectors that transform it into Water.
- Pumpable Water is transported only over Pumpable Water transport elements (Pumpable Water Pipes).
- Pumpable Water may be provided by intake connectors (shoreline, wells).

Quality:
- Pumpable Water providers expose a water-quality tuple (`potability`, `recoverable`) derived from the world source.
- When Pumpable Water is transformed into Water by a pump, the resulting Water inherits the same `potability` and `recoverable`.
- Water Quality & Potability dominance applies on the Water side based on the set of active Water providers (including pumps, barrels, tankers).


#### Fuel

**Fuel** is a combustible resource intended for generator operation and fuel transfer use cases.
- May be **provided** by connectors that observe fuel containers
- May be **consumed** by generator connectors or other fuel sinks
- May be **stored** by connectors that observe fuel containers

Fuel does not currently participate in water potability semantics.
Fuel quality/contamination, if introduced later, must be modeled explicitly as a separate specification.

#### Fuel-Storing Containers (Eligibility)

Fuel storage connectors (e.g., Fuel Barrel Connector) may attach **only** to world objects
that explicitly expose usable, persistent fuel storage in vanilla or via compatible mods.

Eligible objects include:
- Fuel drums or barrels that allow vanilla siphoning or draining
- Containers that maintain a persistent fuel amount and capacity
- Stationary or portable fuel storage objects intended for fuel logistics

Ineligible objects include:
- Decorative or inert metal drums
- Burnable-only barrels that do not store fuel
- Any container that does not expose fuel as a usable resource to vanilla interactions

Eligibility is determined by **observed behavior**, not by sprite, name, or appearance.
An object must:
- Expose a measurable fuel quantity
- Persist fuel state across save/load
- Allow fuel to be transferred via vanilla mechanics or explicit connector actions

Empty but eligible fuel containers remain valid storage connectors.
Such connectors advertise **Store** capability but may be inactive until fuel is present.

#### Non-Assumption Rule (Fuel Containers)

The system must not infer fuel-storage capability from appearance alone
(e.g., assuming all metal drums contain fuel).

Connector attachment must be gated by the presence of explicit fuel-storage behavior
in the observed object.

#### Propane

**Propane** is a pressurized gaseous fuel stored in physical tanks and consumed by specific appliances
(e.g., ovens, grills, heaters, furnaces).

Rules:
- Propane is a distinct resource type and MUST NOT mix with Fuel or Water.
- Propane is consumed only by propane-capable appliances via explicit connectors.
- Propane is stored in portable or stationary tanks.
- Propane transfer is explicit and connector-mediated.

Equalization:
- Propane equalization occurs **only** among connectors with **Store** capability.
- Equalization is event-driven and respects closed valves.
- Connectors without **Store** capability never participate in equalization.

Power:
- Propane appliances do not require electricity by default.
- Electricity requirements, if any, are appliance-specific and do not alter propane semantics.

Quality:
- Propane does not participate in water potability semantics.
- Propane quality/contamination, if modeled later, must be defined in a separate specification.

Intent:
- Propane provides a late-game, logistics-driven energy path distinct from electricity and gasoline.

Summary:
- Water → directly usable by sinks; has potability semantics and dominance
- Pumpable Water → requires pumps; transformed into Water; inherits potability through the pump
- Fuel → combustible liquid fuel for generators and engines; equalizes only among storage connectors
- Propane → pressurized gaseous fuel for appliances; equalizes only among storage connectors


### Failure & Degradation Semantics

### Valves & Flow Control

Valves are explicit, placeable connectors that gate resource flow along an existing connection.

Valve properties:
- Valves do not create or destroy topology
- Valves gate flow on a single edge between two adjacent nodes
- Valves may be opened or closed by the player
- Valves default to **open** when placed (setting-driven)

Placement semantics:
- Valves may be placed anywhere a compatible transport element may be placed
- Placement is never blocked based on network usefulness
- A valve that does not isolate any downstream connections is considered valid but may be ineffective

Behavior:
- When open, a valve behaves identically to the underlying transport element
- When closed, the valve blocks resource flow across that edge
- Network connectivity dynamically reflects valve state changes

Optional feedback:
- Inspection may indicate whether the valve currently isolates downstream connections


Connectors must handle underlying object changes gracefully:

- If the underlying object is removed or destroyed:
  - The connector becomes inactive
  - The network is notified
  - No crashes or dangling references occur
- If the underlying object changes state (e.g., empty barrel, powered-off generator):
  - The connector updates its active/inactive status
  - The network recalculates aggregate availability

Connectors must never assume the continued existence of the underlying object.

#### Observed Object Removal or Ineligibility

If the world object observed by a connector is removed, destroyed, picked up,
or otherwise ceases to meet the connector’s eligibility requirements:

- The connector must immediately deactivate
- The connector must unregister from its network
- Any previously exposed resource availability must drop to zero
- No cached volume, state, or fallback behavior is permitted

If the observed object later reappears or is replaced, a new connector placement
is required to re-establish connectivity.


### Mod Compatibility

Connectors form the primary integration boundary for other mods.

- Other mods may provide compatible source or sink objects
- Integration requires only a compatible connector implementation
- No modification of third-party object logic is required

This design minimizes conflicts and maximizes extensibility.


## 3. Connector Manifest (Capability-Based, Full Model)

This section defines the canonical set of connector types supported by the system.
Connectors advertise **resource-specific capabilities** rather than fixed source/sink roles.

Capabilities include:
- **Provide** — may supply a resource to the network
- **Consume** — may draw a resource from the network
- **Store** — observes an underlying object that maintains volume

A single connector may advertise multiple capabilities.


### Water Connectors

#### Rain Barrel Connector
- Resource: Water
- Capabilities: Provide, Store
- Observed Object: Vanilla Rain Barrel
- Purpose: Direct Water source; preserves vanilla refill, taint, and capacity behavior

#### Shore Intake Connector
- Resource: Pumpable Water
- Capabilities: Provide
- Observed Object: Shoreline Water Tile
- Purpose: Provides Pumpable Water from a body of water (river/lake) via an explicit placed intake

#### Well Intake Connector
- Resource: Pumpable Water
- Capabilities: Provide
- Observed Object: Well
- Purpose: Provides Pumpable Water from wells

#### Water Transport Pipe
- Resource: Water
- Capabilities: None (transport-only)
- Observed Object: None
- Purpose: Orthogonal connectivity for Water networks

#### Pumpable Water Pipe
- Resource: Pumpable Water
- Capabilities: None (transport-only)
- Observed Object: None
- Purpose: Orthogonal connectivity for Pumpable Water networks

#### Water Pump Connector
- Resource: Pumpable Water → Water (transformer)
- Capabilities: Consume (Pumpable Water), Provide (Water), Store
- Observed Object: Pump Object
- Purpose: Transforms Pumpable Water into stored Water; requires electricity

#### Drip Irrigation Pipe
- Resource: Water
- Capabilities: Consume
- Observed Object: Tile / Crop Context
- Purpose: Periodic Water sink that irrigates covered farm tiles while also participating in Water topology

### Fuel Connectors

#### Fuel Barrel Connector
- Resource: Fuel
- Capabilities: Provide, Consume, Store
- Observed Object: Fuel barrel or container
- Purpose: Exposes stored fuel and allows bidirectional transfer

#### Fuel Hose
- Resource: Fuel
- Capabilities: None (transport-only)
- Observed Object: None
- Purpose: Orthogonal connectivity for fuel networks

#### Generator Connector
- Resource: Fuel
- Capabilities: Consume
- Observed Object: Generator
- Purpose: Draws fuel to power a generator

## 4. Network Topology & Lifecycle

### Connectivity Model

Physical connectivity describes player-visible relationships; only connectors and transport nodes participate in network topology.


### Logical Connectivity

Physically connected elements form a **resource network**:

- A network is a connected component
- A network may contain:
  - zero or more connectors with **provide** capability
  - zero or more connectors with **consume** capability
- Resource availability is evaluated at the network level

Resource networks are isolated by resource type.
Connectors may optionally bridge two resource networks by consuming one resource and providing another.


### Network Lifecycle

Network lifecycle is **event-driven** and tied strictly to topology or connector state changes.

#### Registration

Occurs when:
- A node is placed
- A node is loaded with a chunk
- A connector changes active/inactive state

Registration:
- Indexes the node
- Queries adjacent nodes
- Forms, joins, or merges networks

No global scans are permitted.


#### Merge

Occurs when a new connection links multiple networks.
Aggregate availability is recomputed once.


#### Split

Occurs when a removal disconnects a network.
Only the affected component is re-evaluated.


#### Deregistration

Occurs on node removal.
Adjacency is rechecked; splits may occur.


#### Source State Changes

When an observed object affects a connector with **provide** capability:
- Connector updates active/inactive state
- Network availability is recalculated
- No topology changes occur


#### Chunk Load Reconciliation

Nodes register on chunk load.
Deferred merges occur naturally as adjacent chunks load.
No eager rebuilds are allowed.


## 5. Resource Availability Semantics

- Connectors with **provide** capability expose resource availability
- Availability is binary or thresholded, not volumetric
- Networks do not aggregate stored quantities
- World objects retain capacity and refill rules


## 5.1 Water Quality & Potability Semantics

This section defines how water drinkability and contamination are modeled and applied.
Quality affects **effects and consequences**, not availability.


### Quality Dimensions

Water quality is modeled along two orthogonal axes:

- **Availability** — whether water is present at all  
- **Potability** — whether water is safe to drink

Availability is handled by network and connector state.
Potability is handled by quality semantics described here.


### Potability States

The system models exactly three potability states:

- **potable** — safe to drink, no negative effects
- **tainted** — unsafe to drink, recoverable through treatment
- **toxic** — unsafe to drink, not recoverable, usable only with negative effects

Avoid ambiguous terms such as “dirty” or “contaminated” in favor of the explicit states above.


### Quality Exposure

Each connector with **provide** capability exposes:

- `potability`
- `recoverable` (boolean)

Quality is derived from the observed world object.
Transport elements do not alter quality.
Quality semantics apply only to the Water resource type; Pumpable Water inherits quality through pump transformation into Water as defined in Resource Type Definitions.


### Quality Dominance Rule

If multiple active connectors with **provide** capability are connected to the same network,
the **effective output potability** is the worst (most harmful) potability present.

Dominance ordering is:

```
potable < tainted < toxic
```

Inactive providers (e.g. empty or disabled connectors) are ignored for dominance checks.


### Sink Application

Sinks apply the effective output potability to determine consequences.

- No sink prevents consumption automatically
- Consequences are applied after use, not before
- Sink behavior remains consistent with vanilla expectations

Examples:
- Drinking potable water → safe
- Drinking tainted water → sickness
- Drinking toxic water → severe harm
- Irrigation with toxic water → crop damage or failure

Sinks may differentiate behavior based on potability,
but do not override the dominance rule.


### Explicit Non-Behavior

The system must not:

- Mix or average quality across providers
- Dilute toxic water through clean sources
- Propagate quality changes over time
- Perform background quality evaluation

Quality is evaluated only at the time of sink interaction.

### Fuel Equalization Semantics

Fuel behaves differently from Water with respect to storage and flow.

Rules:

- Fuel equalization occurs **only** among connectors with **Store** capability.
- Equalization occurs only within the same Fuel network and respects valves.
- Equalization is event-driven (e.g., on connection, disconnection, valve state change, or drain completion).
- Connectors without **Store** capability never participate in equalization, even if they observe a finite fuel supply.

Implications:

- Fuel barrels, tanker/ISO containers, and station tanks equalize naturally when connected.
- Fuel pumps and generators do not equalize and do not accept backflow.
- Visibility of remaining fuel does not imply participation in equalization.

This model preserves intuitive liquid behavior while preventing unintended backflow into fuel intakes.

## 6. Drain & Consumption Semantics

Drain is **consume-initiated**, **provide-executed**, and **network-coordinated**, but never network-owned.


### Core Principles

- Network determines availability, not quantity
- Connectors mediate all volume mutation
- World objects remain authoritative for storage
- Drain semantics apply uniformly to Water, Fuel, and Propane unless explicitly overridden by resource-specific rules.


### Drain Initiation

Drain occurs when:
- Connector with **consume** capability is enabled
- Network reports at least one active **provide** connector
- A connector-specific trigger occurs

Drain timing is owned by the consuming connector and may be event-driven or periodic.


### Event-Driven Sink Consumption

Used when drain aligns with explicit player actions.

- No background drain
- Triggered by fixture use (sinks, showers, generators)
- Availability checked at interaction time
- Failure handled gracefully

Recommended for:
- House water intake connectors
- Generator connectors
- Player-operated fixtures


### Periodic Sink Consumption

Used for continuous systems.

- Fixed or state-driven interval
- Suspends automatically if unavailable
- Resumes when availability returns

Recommended for:
- Irrigation emitters
- Automated systems

Consumption rates and coverage-related parameters are settings-driven
and are intentionally not fixed by this specification.

### Resource Transformation (Pumps)

Some connectors act as transformers between resource networks.

A pump connector:
- Consumes **Pumpable Water**
- Produces **Water**
- Requires electricity to operate
- Includes **internal Water storage by default**

Pump behavior:
- Pump drains Pumpable Water into its **internal Water storage** while powered and enabled
- Internal storage has an explicit, finite capacity (e.g., 50 units)
- Stored Water is exposed to the Water network via **provide** capability
- Downstream sinks drain Water from pump storage
- When power is lost, pumping stops but stored Water remains available
- When storage is empty, Water availability ceases until refilled

Optional advanced setting:

- `PumpRequiresExternalStorage = true | false`
- Default value: `false`

When enabled:
- Pump internal storage is disabled or minimal
- Pump will not provide Water unless adjacent to a compatible Water storage connector
  (e.g., barrel, tanker)

Pump UI expectations:

- Players must be able to inspect pumps to view:
  - Power state
  - Stored Water amount and capacity
  - Intake status (e.g., active / starved)
- Visual or audio feedback may indicate active pumping (e.g., animation, noise)

Rates, capacities, and spatial constraints associated with pumps
(e.g., internal storage capacity, fill rate, intake limits)
are defined by configuration or sandbox settings and may be tuned
without altering core semantics.

### Source Selection

- Consumer queries network for eligible **provide** connectors
- Network returns eligible set
- Consumer selects deterministically


### Drain Execution

- Consumer requests amount
- Provider connector mutates world object
- Provider updates state if exhausted


### State Change Propagation

If provider state changes:
- Connector updates state
- Network recalculates availability


### Explicit Non-Behavior

- No pooled volumes
- No proportional distribution
- No background draining


## 7. Player Interaction & UX

The system communicates state primarily through **world-visible objects**
(e.g., pipes, valves, coverage sprites, storage levels).
Detailed information is available via inspection or tooltips on individual
connectors and devices.

The system does not provide global or inferred “network health” indicators.
Players are expected to reason about network behavior through layout,
visual state, and local inspection, consistent with vanilla gameplay.

### Pipe Placement & Visual Resolution

Pipe visuals are derived from adjacency.

- No manual orientation
- Neighbor visuals update on change
- Placement preview and inspection feedback supported


### Physical Connectivity

Player-visible connections:
- Barrel ↔ pipe (via connector)
- Pipe ↔ pipe
- Pipe ↔ hose
- Hose ↔ sink

Orthogonal only.
Explicit placement required.


## 8. Non-Functional Guarantees

### Performance Expectations

- Connectivity recalculated only on node placement/removal or connector state change
- Idle cost approaches zero
- Evaluation scales sub-linearly


### Persistence Expectations

- Save/load safe
- Chunk-safe
- Multiplayer-safe
- Indexes rebuilt, not stored


### Multiplayer Expectations

- Server authoritative
- Clients request actions only
- Minimal replication


### Modularity & Extensibility

- New resources supported
- New connectors added without core changes
- Sandbox options affect policy, not architecture


### Default Valve State Setting

The system provides a sandbox/configuration setting:

- `DefaultValveState = open | closed`
- Default value: `open`

This setting determines the initial state of all valve connectors when placed.


## Optional Degradation & Environmental Damage

This section defines **optional, settings-driven mechanics** that introduce wear,
maintenance, and environmental damage to infrastructure components.

These mechanics are **non-normative** and must be explicitly enabled via settings.
Core system semantics do not depend on their presence.

---

### Degradation Scope

Degradation applies only to **active or mechanical connectors**, not passive transport.

Eligible examples:
- Pumps
- Generators
- Propane-powered appliances
- Other connectors with moving or powered components

Ineligible examples:
- Passive pipes and hoses
- Static storage containers
- Decorative or inert objects

---

### Degradation Model

When enabled, degradation is modeled as **use-based wear**, not background ticking.

- Wear accumulates only when a connector actively operates
- Wear may be tracked as:
  - operating hours
  - completed cycles
  - discrete usage events
- No per-tick or background degradation is permitted

---

### Failure Progression

Degradation should progress through observable stages:

1. Reduced efficiency (slower operation, higher consumption)
2. Increased noise or disruption
3. Intermittent failure to operate
4. Hard failure requiring repair

Instant catastrophic failure is discouraged except in extreme cases.

---

### Maintenance & Repair

Degradation is mitigated through **explicit player actions**, not automatic recovery.

- Right-click actions such as “Service”, “Repair”, or “Tune”
- Requires appropriate tools, time, and skills
- May partially or fully reset wear
- May overlap with tuning/optimization mechanics

Maintenance actions must be:
- Visible
- Intentional
- Inspectable

---

### Environmental Damage (Optional)

When enabled, certain connectors may be damaged by environmental interactions.

Examples:
- Vehicles driving over exposed or surface-laid connectors
- Explosions or fires damaging nearby infrastructure

Constraints:
- Damage checks must be event-driven, not continuous
- Only exposed or fragile connectors may be eligible
- Damage probability should scale with contextual factors
  (e.g., vehicle speed, mass, connector type)

Environmental damage must always provide:
- Immediate audiovisual feedback
- A visible damaged state
- Clear inspection feedback explaining failure

---

### Settings & Tuning

All degradation and environmental damage behavior must be:
- Disabled by default
- Controlled via sandbox or configuration settings
- Tunable in severity and frequency

These mechanics exist to increase tension and realism for players who desire it,
without imposing additional burden on default gameplay.


## 9. Open Questions

- How is water consumption balanced at sinks?
- Do hoses differ mechanically from pipes?
- How much vanilla logic should be intercepted vs observed?