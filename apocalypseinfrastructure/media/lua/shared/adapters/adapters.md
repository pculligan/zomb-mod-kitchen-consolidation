# Adapter Target Inventory

This document is an authoritative inventory of **Project Zomboid game world objects** that the infrastructure system intends to observe, adapt, or synthesize.

The purpose of this table is to:
- make scope explicit
- avoid reliance on non-existent APIs
- guide adapter implementation order
- distinguish vanilla, modded, and synthesized objects

If a game object is not listed here, adapters should not interact with it without updating this file.

---

## Connector Specification

The adapter system models infrastructure as a network of interconnected objects with defined roles such as Providers, Consumers, Pipes, Controllers, and Entities.

---

## Transient Consumers (Important)

Not all Consumers are persistent topology nodes.

**Fixtures such as sinks, toilets, showers, and appliances are modeled as _transient consumers_.**

### What this means

- A transient consumer **does not exist at world load**
- It is **created only when an interaction occurs** (e.g. player uses a sink)
- It participates in topology **only for the duration of the request**
- It is detached and discarded immediately after flow is applied

### Rationale

Persistently modeling every sink or fixture as a Consumer would:
- create tens of thousands of unnecessary nodes
- increase topology maintenance cost
- complicate save/load and chunk streaming
- provide no gameplay benefit

Transient consumers avoid all of these problems.

### Lifecycle of a transient consumer

1. Player interacts with a fixture
2. Controller creates a temporary `Entity`
3. `Consumer` trait is applied
4. Entity is attached to the network
5. `request()` and `applyPlan()` are executed
6. Entity is detached and destroyed

### Invariants

- **Only Providers and Pipes are persistent topology nodes**
- Consumers created by controllers must always be transient unless explicitly documented otherwise
- Transient consumers must never be cached or reused

---


## Game World Object Inventory
| Game Object | Zomboid / Mod Identifier | Consumes | Provides | Source | Exists | Adapter Type | Planned Adapter | Placement Restrictions | Art Ideas | Implementation / Gameplay / Functional Notes |
|------------|--------------------------|----------|----------|--------|--------|--------------|-----------------|------------------------|-----------|---------------------------------------------|
| Rain Collector Barrel (Small) | `IsoRainCollectorBarrel` | — | Water | Vanilla | Yes | Connector | `RainBarrelConnector` | Exterior only; occupies tile | — | — |
| Rain Collector Barrel (Large) | `IsoRainCollectorBarrelLarge` *(TBD)* | — | Water | Vanilla | Partial | Connector | `RainBarrelConnector` | Exterior only; occupies tile | — | — |
| House Water Connection (Boundary) | Synthesized | — | Water | AI | No | Connector | `HouseWaterBoundaryConnector` | Exterior wall of house; one per house | — | — |
| Water Pump | Synthesized | PumpableWater | Water | AI | No | Entity + Controller | `WaterPumpEntity` | Adjacent to intake; powered | — | — |
| River / Lake | `IsoWater` / world tile | — | PumpableWater | Vanilla | Yes | Synthesized Connector | `WaterIntakeConnector` | Shoreline tiles only; spacing limit | — | — |
| Well | `IsoObject` (map-specific) | — | PumpableWater | Vanilla | Partial | Synthesized Connector | `WellConnector` | Ground tile; one per well object; spacing limit | — | — |
| Gas Station Pump | `IsoFuelPump` | — | Fuel | Vanilla | Yes | Connector | `FuelPumpConnector` | Fixed world placement | — | — |
| Gas Station Storage | Implicit | — | Fuel | Vanilla | Implicit | Synthesized | `FuelStationStorage` | Not placeable | — | — |
| Fuel Barrel | Mod-specific | — | Fuel | Mod | Common | Connector | `FuelBarrelConnector` | Ground tile; exterior | — | — |
| ISO Container (Fuel) | Mod-specific | — | Fuel | Mod | Common | Connector | `FuelISOConnector` | Ground tile; large footprint | — | — |
| Fuel Pump | Synthesized | Fuel | Fuel | AI | No | Entity + Controller | `FuelPumpEntity` | Inline with fuel network | — | — |
| Propane Tank (Small) | `IsoPropaneTank` | — | Propane | Vanilla | Yes | Connector | `PropaneTankConnector` | Ground tile; exterior | — | — |
| Propane Tank (Large) | `IsoPropaneTankLarge` *(TBD)* | — | Propane | Vanilla | Partial | Connector | `PropaneTankConnector` | Ground tile; exterior | — | — |
| Propane Tank Hookup | Synthesized | — | Propane | AI | No | Connector + Storage | `PropaneTankHookupConnector` | Exterior only; fixed position | White metal cage / hardware-store propane rack | Acts like a shelf holding propane tanks; provides Propane only when tanks are present; capacity derived from inventory; no flow without tanks |
| Electrical Grid | Global system | — | Electricity | Vanilla | Implicit | Synthesized | `GridElectricityConnector` | Global; not placeable | — | — |
| Generator | `IsoGenerator` | Fuel | Electricity | Vanilla | Yes | Connector + Controller | `GeneratorConnector` | Exterior only; noise rules apply | — | — |
| Battery | `IsoBattery` *(inventory)* | Electricity | Electricity | Vanilla | Yes | Connector | `BatteryConnector` | Inventory or ground tile | — | — |
| Solar Panel | Mod-specific | — | Electricity | Mod | Common | Connector | `SolarPanelConnector` | Exterior roof or ground | — | — |
| Sink (Kitchen/Bath) | `IsoSink` / `IsoObject` (type check) | Water | — | Vanilla | Yes | Controller (Transient Consumer) | `WaterUseController` | Interior fixture; no placement by mod | — | — |
| Shower / Bathtub | `IsoBath` / `IsoObject` (type check) | Water | — | Vanilla | Yes | Controller (Transient Consumer) | `WaterUseController` | Interior fixture; no placement by mod | — | — |
| Toilet | `IsoToilet` / `IsoObject` (type check) | Water | — | Vanilla | Yes | Controller (Transient Consumer) | `WaterUseController` | Interior fixture; no placement by mod | — | — |
| Washing Machine | `IsoObject` (sprite-based) | Water | — | Vanilla | Partial | Controller (Transient Consumer) | `WaterUseController` | Interior appliance; powered | — | — |
| Floor Pipe | Visual tile | — | — | Vanilla | Visual | Placement / Entity | `Pipe` | One per resource per tile | — | — |
| Wall Pipe | Visual tile | — | — | Vanilla | Visual | Placement / Entity | `Pipe` | One per face per resource | — | — |
| Valve | Mod sprite / Synth | — | — | Mod | Partial | Entity + Connector | `Valve` | Exactly two connections; surface-specific | — | — |
| Tanker Hookup | Synthesized | Water, Fuel | Water, Fuel | AI | No | Connector | `TankerHookupConnector` | Exterior; vehicle-adjacent | — | — |

## Infrastructure Things
| Thing | Resource(s) | Intrinsic Connections | Storage | Movable | Placement Notes | Tool / Skill Requirements | Gameplay / Authoring Notes |
|------|-------------|-----------------------|---------|---------|------------------|---------------------------|----------------------------|
| Water Pipe | Water | Floor + Wall faces (implicit) | — | Yes | One per face per tile; obeys valve rules | Wrench | Pure topology element; visuals derived from adjacency |
| Water Valve | Water | Exactly 2 surface connections | — | Yes | Must connect exactly two pipe surfaces | Wrench | Gating element; open/closed state |
| Rain Collector Barrel (Small) | Water | Floor connection | Yes (Small) | Yes | Exterior only | Hammer | Vanilla-compatible |
| Rain Collector Barrel (Large) | Water | Floor connection | Yes (Large) | Yes | Exterior only | Hammer | Higher capacity |
| Home Propane Tank (≈200 gal) | Propane | Floor connection | Yes | Yes (heavy) | Exterior ground tile | Wrench + Strength | Backyard propane tank; movable with effort |
| Commercial Propane Tank (≈1000 gal) | Propane | Floor connection | Yes | No | Exterior ground tile; large footprint | Construction skill | Industrial-scale storage |
| Propane Tank Hookup | Propane | Floor connection | No (inventory-based) | No | Exterior; fixed | Wrench | Shelf-like structure holding propane tanks |
| Water Pump | PumpableWater → Water | Floor + inline pipe | No (transforms) | No | Adjacent to intake | Power + Mechanics | Requires power; creates pressure |
| Fuel Pump | Fuel | Inline pipe | No | No | Inline with fuel network | Power + Mechanics | Pressurizes / moves fuel |
| House Water Boundary | Water | Wall connection | No | No | Exterior wall only; one per house | Wrench | Boundary between outside network and interior usage |
| Tanker Hookup | Water, Fuel | Floor connection | No | No | Exterior; vehicle-adjacent | Wrench | Bidirectional transfer to vehicles |


## Notes

- "Synthesized" objects do not exist as single IsoObjects and must be modeled explicitly.
- Many vanilla pipes are **visual-only** and rely entirely on backend topology.
- Adapters must never invent semantics; synthesized behavior must be documented and optional.


- Consumer entities for fixtures should be created only at interaction time, never at bootstrap
