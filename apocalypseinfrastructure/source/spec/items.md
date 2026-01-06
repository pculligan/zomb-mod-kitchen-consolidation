## Water Resources

This section covers all connectors and transport elements related to **Water** and **Pumpable Water**.


### Water — Directly Usable Water

These connectors participate in **Water networks** and expose water that can be consumed by sinks.

| Connector | Capabilities | Drain Mode | Observes | Notes |
|---------|--------------|------------|----------|------|
| Rain Barrel Connector | Provide, Store | — | Rain Barrel | Direct Water source; inactive when empty |
| Water Transport Pipe | — | — | — | Carries Water only |
| Drip Irrigation Pipe | Consume | Periodic | Tile / Crop Context | Consumes Water; irrigates covered farm tiles |
| House Water Intake Connector | Consume | Event | House / Building | Consumes water only when fixtures are used |
| House Water Source Connector | Provide | — | House / Building | Represents municipal water when available |
| Water Valve | — | — | — | Gates Water flow; defaults to open |

#### Rain-Collecting Containers (Eligibility)

The Rain Barrel Connector may attach **only** to world objects that explicitly support
rain collection and water storage in vanilla or via compatible mods.

Eligible objects include:
- Crafted wooden rain collector barrels
- Crafted metal rain collector barrels (via metalworking)
- Map-placed rain collector barrels with equivalent behavior

Ineligible objects include:
- Generic closed metal drums
- Decorative barrels or drums that do not collect rain
- Any container that does not explicitly expose rain collection behavior

Eligibility is determined by **observed behavior**, not by appearance.
An object must:
- Collect rain automatically when placed outdoors
- Maintain a persistent water amount and capacity
- Expose water as a usable resource to vanilla interactions

The connector must not assume that a visually open container collects rain unless
the underlying object explicitly supports rain collection.

#### Non-Assumption Rule

The system must not infer rain-collection capability from sprite state alone
(e.g., "open top" appearance).

Connector attachment must be gated by the presence of explicit rain-collection
behavior in the observed object.


### Pumpable Water — Requires Pumping

These connectors participate in **Pumpable Water networks** and expose water that must be transformed by a pump before use.

| Connector | Capabilities | Drain Mode | Observes | Notes |
|---------|--------------|------------|----------|------|
| Shore Intake Connector | Provide | Event | Shoreline Water Tile | Provides Pumpable Water; minimum spacing applies |
| Well Intake Connector | Provide | Event | Well | Provides Pumpable Water |
| Pumpable Water Pipe | — | — | — | Carries Pumpable Water only |
| Pumpable Water Valve | — | — | — | Gates Pumpable Water flow; defaults to open |


### Water Pumps — Resource Transformation

Pumps bridge **Pumpable Water networks** to **Water networks**.

| Connector | Capabilities | Drain Mode | Observes | Notes |
|---------|--------------|------------|----------|------|
| Water Pump Connector | Consume (Pumpable), Provide (Water), Store | Periodic | Pump Object | Requires electricity; transforms Pumpable Water into stored Water (explicit internal capacity) |


### Drip Irrigation Pipe — Coverage Semantics

Drip irrigation pipes combine transport and irrigation behavior in a single connector.

Coverage behavior:

- Coverage area is selected from a small set of discrete shapes (e.g. 3×3, 5×5)
- Coverage is **center-anchored** on the pipe’s placement tile
- Coverage applies **only to farmable tiles**; non-farm tiles are ignored
- Drain is executed **once per pipe per interval**, regardless of coverage size
- All covered tiles receive identical irrigation effects

Visual representation:

- A pre-authored coverage sprite is placed when the pipe is placed
- The sprite visually communicates the full coverage area
- The coverage sprite renders below crops and world objects
- The coverage sprite disappears immediately when the pipe is removed

The coverage sprite is representational only and does not participate in topology or drain logic.


## Fuel Resources

This section covers all connectors and transport elements related to **Fuel**.


### Fuel — Combustible Resource

| Connector | Capabilities | Drain Mode | Observes | Notes |
|---------|--------------|------------|----------|------|
| Fuel Barrel Connector | Provide, Consume, Store | Event | Fuel Container | Equalizable fuel storage |
| Tanker / ISO Container Connector | Provide, Consume, Store | Event | Tanker / ISO Container | Mobile or modular equalizable fuel storage |
| Gas Station Tank Connector | Provide, Consume, Store | Event | Station Underground Tank | Equalizable station fuel storage |
| Fuel Hose | — | — | — | Transport-only; visually distinct |
| Gas Station Pump Connector | Provide | Event | Pump Object | Requires electricity; draws fuel from station tank only |
| Generator Connector | Consume | Event | Generator | Consumes fuel; does not equalize |

### Fuel Connector Notes

- Only connectors with **Store** capability participate in fuel equalization.
- Fuel equalization is event-driven and respects closed valves.
- Gas Station Pump Connectors observe station fuel levels but never accept fuel or equalize.
- Refilling a gas station is accomplished by connecting a Tanker / ISO Container Connector to the Gas Station Tank Connector.
- Power gates gas station pumps but does not affect station tank equalization.


## Propane Resources

This section covers all connectors and transport elements related to **Propane**.

---

### Propane — Pressurized Gaseous Fuel

| Connector | Capabilities | Drain Mode | Observes | Notes |
|---------|--------------|------------|----------|------|
| Propane Tank Connector | Provide, Consume, Store | Event | Propane Tank Item | Equalizable propane storage (portable or stationary) |
| Large Propane Tank Connector | Provide, Consume, Store | Event | Large Propane Tank | High-capacity stationary propane storage |
| Industrial Propane Storage Connector | Provide, Consume, Store | Event | Industrial Propane Vessel | Very high-capacity storage for industrial/factory use |
| Propane Hose | — | — | — | Transport-only; visually distinct from water and fuel |
| Propane Valve | — | — | — | Gates Propane flow; defaults to open |
| House Propane Service Connector | Consume | Event | House / Building | Supplies propane to propane-capable indoor appliances |
| Propane Appliance Connector | Consume | Event | Appliance | Outdoor or standalone propane appliances (e.g., grills) |

---

### Propane Connector Notes

- Only connectors with **Store** capability participate in propane equalization.
- Propane equalization is event-driven and respects closed valves.
- House Propane Service Connectors consume propane **only** in response to appliance use (event-driven).
- Not all appliances are propane-capable; propane usage is determined by appliance type or metadata.
- Houses may simultaneously support propane service and electricity without conflict.
- Propane transport elements must not connect to Water, Pumpable Water, or Fuel elements.

### Buildable Structures & Implicit Connectors

Some buildable tiles or placed world objects may automatically create one or more connectors
when constructed.

Examples:
- A house propane hookup tile may automatically create a House Propane Service Connector.
- A built propane tank structure may automatically create a Propane Tank Connector.

This behavior is an implementation convenience only.
All connectors created implicitly are equivalent to manually placed connectors and
participate fully in network semantics.

## Settings (Defaults & Tunables)

The following settings capture known rate, capacity, and spatial constraints.
Values listed are **recommended defaults** and are expected to be configurable
via sandbox or mod settings. These defaults exist to reduce ambiguity during
implementation and testing.

| Setting Key | Description | Recommended Default |
|------------|-------------|---------------------|
| Pump.InternalStorageCapacity | Water pump internal Water storage capacity | 50 units |
| Pump.FillRate | Rate at which pumps convert Pumpable Water to Water | 5 units / hour |
| ShoreIntake.MinSpacing | Minimum distance between Shore Intake connectors | 10 tiles |
| DripIrrigation.Coverage | Coverage footprint for drip irrigation pipes | 3×3 |
| DripIrrigation.DrainRate | Water consumed per irrigation interval | 1 unit / hour |
| Fuel.EqualizationEnabled | Enable fuel equalization among Store connectors | true |
| Propane.EqualizationEnabled | Enable propane equalization among Store connectors | true |
| Valve.DefaultState | Default state of valves when placed | open |
| Pump.RequiresExternalStorage | Require adjacent Water storage for pumps | false |

Notes:
- These settings do not alter core semantics defined in `spec.md`.
- Changing values affects balance and pacing only.
- Implementation may choose appropriate time units consistent with the engine.

## Notes on Drain Modes

- **Event** — Drain occurs only in response to explicit player actions (e.g., using a fixture, turning on a generator).
- **Periodic** — Drain occurs on a fixed or state-driven interval while enabled (e.g., irrigation).
- **—** — No drain behavior; transport or storage only.

Drain mode is owned by the connector and does not affect network topology.



## Valve Behavior Notes

- Valves gate flow for a specific resource type (Water or Pumpable Water)
- Valves default to **open** on placement (configurable via settings)
- Detailed valve semantics are defined in `spec.md`

## Extensibility

This inventory is expected to grow over time.

Future additions may include:
- Pumps (water, fuel)
- Filters or treatment connectors
- Valves or isolation connectors
- Advanced storage (tanks, cisterns)
- Optional electricity-as-resource connectors (behind sandbox settings)
- Propane-powered appliances and infrastructure

All future connectors must conform to the capability-based connector model defined in the main specification.


## Visual & Topological Clarity

Transport elements are visually distinct by resource type:

- Pumpable Water Pipes
- Water Pipes
- Fuel Hoses

This ensures players can visually identify valid connections and avoid accidental cross-connection.

### Water Pump — Storage Semantics

Water pumps include internal Water storage by default.
Authoritative storage behavior and UI requirements are defined in `spec.md` under
§6 “Resource Transformation (Pumps)”.