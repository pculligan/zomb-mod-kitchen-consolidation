# Adapters

The `adapters/` layer is the boundary between the **engine‑agnostic backend** (entities, topology, traits, allocation) and the **Project Zomboid runtime** (IsoObjects, tiles, events, rendering).

Adapters must be:
- thin
- declarative
- reactive
- free of business logic

All game logic lives *outside* this layer.

---

## Folder Overview

```
adapters/
├── bootstrap
├── connectors
├── controllers
├── observers
└── render
```

Each folder has a **single, non‑overlapping responsibility**.

---

## `bootstrap/`

**Purpose:**
Discover existing world objects and create or restore backend entities at game load / chunk load.

**When it runs:**
- world start
- save load
- chunk load / unload

**Responsibilities:**
- scan IsoObjects
- determine eligibility
- instantiate Entity + traits
- call `entity:attach()` / `entity:detach()`

**Must NOT:**
- mutate gameplay state
- perform allocation or drain
- decide placement
- render anything

### Planned files

- `WorldBootstrap.lua`  
  Entry point for bootstrapping adapters

- `WaterBootstrap.lua`  
  Discovers water‑related IsoObjects (rain barrels, house plumbing)

- `FuelBootstrap.lua` *(future)*  
  Discovers fuel tanks, pumps

- `PropaneBootstrap.lua` *(future)*

---

## `connectors/`

**Purpose:**
Adapt a *single* IsoObject into a *single* Entity with traits and capabilities.

**When it runs:**
- object creation
- object discovery
- object state change

**Responsibilities:**
- map IsoObject state → Capabilities
- keep state synchronized (capacity, current, enabled)
- expose `attach()` / `detach()` lifecycle

**Must NOT:**
- perform topology logic
- perform allocation
- handle events
- render

### Planned files

#### Water

- `Water/RainBarrelConnector.lua`  
  Adapts vanilla rain collectors into Provider + Storage entities

- `Water/HouseWaterConnector.lua`  
  Adapts house plumbing fixtures into Consumer entities

- `Water/WaterPipeConnector.lua` *(later)*  
  Optional adapter if pipes ever require runtime state

#### Fuel *(future)*

- `Fuel/FuelTankConnector.lua`
- `Fuel/FuelPumpConnector.lua`

---

## `controllers/`

**Purpose:**
Initiate behavior in response to player actions or game events.

**When it runs:**
- player uses fixture
- generator runs
- periodic ticks (irrigation, pumps)

**Responsibilities:**
- call `consumer:request()`
- call `consumer:applyPlan()`

**Must NOT:**
- store state
- decide topology
- render

### Planned files

- `Water/WaterUseController.lua`  
  Handles water usage from sinks, showers, etc.

- `Fuel/FuelConsumptionController.lua` *(future)*

---

## `observers/`

**Purpose:**
React to world state changes that occur *outside* the infrastructure system.

**When it runs:**
- rain start / stop
- object destroyed
- power on/off
- inventory change

**Responsibilities:**
- update Capabilities based on world state
- enable / disable Providers
- detach Entities when objects disappear

**Must NOT:**
- initiate flow
- allocate resources
- render

### Planned files

- `RainObserver.lua`  
  Updates rain barrel storage during rainfall

- `PowerObserver.lua` *(future)*

---

## `render/`

**Purpose:**
Translate Entity visual state into sprites and tile graphics.

**When it runs:**
- placement preview
- entity attach/detach
- neighbor change
- valve open/close

**Responsibilities:**
- choose sprites
- apply tile overlays
- update visuals only

**Must NOT:**
- change topology
- change storage
- initiate flow

### Planned files

- `PipeRenderer.lua`
- `ValveRenderer.lua`

---

## Design Rules (Important)

- Adapters are **not reusable logic** — they are glue
- If something feels complex here, it belongs elsewhere
- Adapters may call backend APIs, never the other way around
- Each adapter should be testable with PZ stubs

---

## Development Order (Recommended)

1. `connectors/Water/RainBarrelConnector.lua`
2. `controllers/Water/WaterUseController.lua`
3. `observers/RainObserver.lua`
4. `render/PipeRenderer.lua`

Everything else builds naturally from those.

---

# Connector Specification

This section formalizes the **connector contracts**. Each connector is a thin adapter between a specific Project Zomboid IsoObject (or game concept) and the backend Entity + Traits model.

The tables below are normative: they describe what each connector *must* do and *must not* do.

---

## Common Connector Contract

All connectors share the following structure and lifecycle:

| Aspect | Requirement |
|------|------------|
| Maps | One IsoObject → one Entity |
| Owns Entity | Yes |
| Attaches | Calls `entity:attach()` when valid |
| Detaches | Calls `entity:detach()` on destruction / invalidation |
| Mutates Topology | **Never** |
| Performs Allocation | **Never** |
| Renders | **Never** |

### Required Inputs

- `isoObject` (or equivalent game handle)
- World position `(x, y, z)`
- Observed game state snapshot (capacity, amount, enabled)

### Required Outputs

- Fully configured `Entity`
- Traits applied (`Storage`, `Provider`, `Consumer` as appropriate)

---

## Water Connectors

### `RainBarrelConnector`

| Attribute | Value |
|---------|------|
| Resource | Water |
| Traits | Storage, Provider |
| Consumes | No |
| Provides | Yes |
| Storage Source | IsoRainCollectorBarrel |

#### Responsibilities

| Responsibility | Description |
|---------------|------------|
| Storage Sync | `store.current` ↔ barrel water amount |
| Capacity Sync | `store.capacity` ↔ barrel max capacity |
| Enable State | Enabled if barrel exists and not destroyed |
| Attach Timing | On discovery or creation |
| Detach Timing | On destruction or invalidation |

#### Explicitly Not Responsible For

- Rain detection logic (handled by `RainObserver`)
- Flow initiation
- Placement rules
- Rendering

---

### `HouseWaterConnector`

| Attribute | Value |
|---------|------|
| Resource | Water |
| Traits | Consumer |
| Consumes | Yes |
| Provides | No |
| Storage | None |

#### Responsibilities

| Responsibility | Description |
|---------------|------------|
| Consumer Setup | Applies `Consumer` trait |
| Event Binding | Subscribes to fixture-use events |
| Request Logic | Calls `consumer:request()` |
| Apply Logic | Calls `consumer:applyPlan()` |

#### Explicitly Not Responsible For

- Allocation strategy
- Provider selection
- Storage mutation
- Topology logic

---

### `WaterPipeConnector` *(optional / future)*

This connector exists **only if** pipe IsoObjects require runtime state.

| Attribute | Value |
|---------|------|
| Resource | Water |
| Traits | None (Entity only) |
| Purpose | Runtime rehydration |

Most pipe behavior is handled directly by `Pipe` entities and placement logic. This connector should remain empty unless proven necessary.

---

## Fuel Connectors *(Planned)*

### `FuelTankConnector`

| Attribute | Value |
|---------|------|
| Resource | Fuel |
| Traits | Storage, Provider |
| Storage Source | IsoFuelTank |

Responsibilities mirror `RainBarrelConnector` with fuel-specific metadata.

---

### `FuelPumpConnector`

| Attribute | Value |
|---------|------|
| Resource | Fuel |
| Traits | Provider |
| Requires Power | Yes |

This connector will integrate with power state observers.

---

## Propane Connectors *(Planned)*

### `PropaneTankConnector`

| Attribute | Value |
|---------|------|
| Resource | Propane |
| Traits | Storage, Provider |

---

## Electricity Connectors *(Planned)*

Electricity is modeled as a resource but may remain hidden behind settings.

### `GeneratorConnector`

| Attribute | Value |
|---------|------|
| Resource | Electricity |
| Traits | Provider |
| Storage | Optional (fuel-backed) |

---

## Invariants Across All Connectors

- Connectors **never** decide allocation strategy
- Connectors **never** traverse topology
- Connectors **never** infer neighbors
- All adjacency is resolved by `Entity` + `Topology`

If a connector needs information outside its IsoObject, that logic belongs in:
- `controllers/` (for actions)
- `observers/` (for reactions)
- `placement/` (for legality)

---

## Notes for Future Contributors

If you find yourself wanting to:
- loop over neighbors
- inspect networks
- perform math on resources

You are in the wrong layer.

Stop and move that logic into the backend.
