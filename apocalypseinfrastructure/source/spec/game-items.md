| Name | Narrative Purpose | Concept | Inventory | Resource Storage | Resource Provided | Resource Consumed | Requires Electricity | Makes Noise | Needs Maintenance | Needs Exposure | Structural Load | Vertical Clearance Required (levels) | Placement Anchors | Topological Requirements | Minimum Separation (tiles) | Failure Response | Failure Triggers | Faces Occupied | Movable | Placement Notes | Tool / Skill Requirements | Gameplay / Authoring Notes |
|------|-------------------|---------|-----------|------------------|-------------------|-------------------|----------------------|-------------|-------------------|---------------|------------------|-------------------------------------|-------------------|--------------------------|----------------------------|------------------|------------------|-----------------------|---------|------------------|---------------------------|----------------------------|
| Car Battery Bank | Electricity | Storage (Electric) | Car Batteries (`Base.CarBattery`, mod variants) | Electricity (derived from inventory) | Electricity | Electricity | No | none | a little | none | some | 0 | clear space | floor face | 1 | nonfunctional | time, damage | Floor connection | No | Utility room | Electrical + Mechanics | Acts like a shelf and charger; aggregates charge from installed batteries and consumes Electricity to recharge them |
| Bike Generator | Electricity | Generator (Electric, Human) | Bicycle (modded) | — | Electricity | — | No | a little | a little | none | some | 0 | clear space | floor face | 1 | reduced efficacy | time, stamina | Floor connection | Yes | Stationary bike setup | Mechanics + Fitness | Human-powered generator; provides Electricity proportional to player stamina/calories burned; noisy and inefficient but works without fuel or grid |
| Electrical Breaker / Switch | Electricity | Breaker (Electric) | — | — | — | — | Yes | none | a little | none | none | 0 | — | between two | 0 | removed | support removed | Exactly 2 surface connections | Yes | Must connect exactly two Electrical conduit surfaces | Screwdriver | Gates Electricity flow only |
| Electrical Conduit | Electricity | Pipe (Electric) | — | — | — | — | Yes | none | none | none | none | 0 | — | floor face &#124; wall face | 0 | removed | support removed | Floor + Wall faces (implicit) | Yes | One per face per tile; electrical-only | Wrench | Carries Electricity only; visually distinct from fluid pipes |
| Large Wind Generator | Electricity | Generator (Electric, Wind) | — | — | Electricity | — | No | a lot | a little | a lot | a lot | 2 | clear space | floor face | 6 | reduced efficacy | time, exposure loss, damage | Floor connection (large footprint / structure) | No | Dedicated structure | Carpentry + Electrical | High-capacity wind-driven generator; weather-dependent; late-game infrastructure |
| Military Generator (15 kW) | Electricity | Generator (Electric, Fuel) | — | Fuel | Electricity | — | Yes | a lot | a lot | none | some | 0 | clear space | floor face | 1 | nonfunctional | time, damage | Floor connection | No | Large footprint | Mechanics + Electrical | MEP-804A / HDT GETS; high-output base power |
| Military Generator (5 kW) | Electricity | Generator (Electric, Fuel) | — | Fuel | Electricity | — | Yes | a lot | a lot | none | some | 0 | clear space | floor face | 1 | nonfunctional | time, damage | Floor connection | No | Noise + emissions | Mechanics + Electrical | MEP-802A style; rugged, reliable, moderate output |
| Propane Generator (Fixed) | Electricity | Generator (Electric, Propane) | Propane | Propane | Electricity | — | No | a lot | a lot | none | some | 0 | clear space | floor face | 1 | nonfunctional | time, damage | Floor connection | No |  | Construction + Electrical | Large, fixed propane generator |
| Propane Generator (Portable) | Electricity | Generator (Electric, Propane) | Propane Tanks | Propane (inventory-derived) | Electricity | — | No | a lot | a lot | none | some | 0 | clear space | floor face | 1 | nonfunctional | time, damage | Floor connection | No |  | Mechanics + Electrical | Tank-swapped generator; quieter than fuel |
| Small Wind Generator | Electricity | Generator (Electric, Wind) | — | — | Electricity | — | No | a lot | a little | some | some | 1 | clear space | floor face | 3 | reduced efficacy | time, exposure loss, damage | Floor connection (2–4 tile footprint) | No | Open area required | Carpentry + Electrical | Passive electricity provider; low output; wind-dependent |
| Fuel Pipe | Fuel | Pipe (Fuel) | — | — | — | — | No | none | none | none | none | 0 | — | floor face &#124; wall face | 0 | removed | support removed | Floor + Wall faces (implicit) | Yes | One per face per tile | Wrench | Carries Fuel only; visually distinct (hose or metal pipe) |
| Fuel Pump | Fuel | Pump (Fuel, Powered) | — | — | Fuel | Fuel | Yes | a little | a lot | none | some | 0 | — | inline | 0 | reduced efficacy | time, damage, power loss | Inline pipe | No |  | Power + Mechanics | Acts as a resource activator, not storage. Contains a small internal buffer that refills only from attached Gas Station Storage. Requires power to refill. Provides Fuel only while buffer > 0. |
| Fuel Tanker Hookup | Fuel | Hookup (Fuel) | — | — | Fuel | Fuel | No | a little | a little | none | none | 0 | vehicle-docking point | inline | 1 | nonfunctional | support removed, time | Floor connection | No |  | Wrench | Static hookup point. Becomes active only when a compatible vehicle or trailer is explicitly docked by the player. While docked, temporarily exposes a Provider or Consumer backed by the vehicle’s tank; direction (fill vs drain) is player-selected. Inert when no vehicle is connected. |
| Fuel Valve | Fuel | Valve (Fuel) | — | — | — | — | No | none | a little | none | none | 0 | — | between two | 0 | removed | support removed | Exactly 2 surface connections | Yes | Must connect exactly two Fuel pipe surfaces | Wrench | Gates Fuel flow only |
| Commercial Propane Tank | Propane | Storage (Propane) | — | Propane | Propane | — | No | none | a little | none | a lot | 0 | clear space | floor face | 1 | nonfunctional | time, damage | Floor connection | No | Large footprint | Construction skill | Industrial-scale storage (≈1000 gal) |
| Home Propane Tank | Propane | Storage (Propane) | — | Propane | Propane | — | No | none | a little | none | some | 0 | clear space | floor face | 1 | nonfunctional | time, damage | Floor connection | No |  | Wrench + Strength | Backyard propane tank (≈200 gal); heavy, not movable without equipment |
| Propane Pipe | Propane | Pipe (Propane) | — | — | — | — | No | none | none | none | none | 0 | — | floor face &#124; wall face | 0 | removed | support removed | Floor + Wall faces (implicit) | Yes | One per face per tile | Wrench | Carries Propane only; visually distinct |
| Propane Storage Cage | Propane | Storage (Propane) | Propane Tanks (`Base.PropaneTank`, `TW.LargePropaneTank`, `TW.HugePropaneTank`) | Propane (derived from inventory) | Propane | — | No | none | a little | none | some | 0 | clear space | floor face | 1 | nonfunctional | time, damage | Floor connection | No | Fixed | Wrench | Shelf-like structure; provides Propane only while tanks are present |
| Propane Tanker Hookup | Propane | Hookup (Propane) | — | — | Propane | Propane | No | a little | a little | none | none | 0 | vehicle-docking point | inline | 1 | nonfunctional | support removed, time | Floor connection | No |  | Wrench | Static hookup point. Becomes active only when a compatible vehicle or trailer is explicitly docked by the player. While docked, temporarily exposes a Provider or Consumer backed by the vehicle’s tank; direction (fill vs drain) is player-selected. Inert when no vehicle is connected. |
| Propane Valve | Propane | Valve (Propane) | — | — | — | — | No | none | a little | none | none | 0 | — | between two | 0 | removed | support removed | Exactly 2 surface connections | Yes | Must connect exactly two Propane pipe surfaces | Wrench | Gates Propane flow only |
| Pumpable Water Pipe | PumpableWater | Pipe (PumpableWater) | — | — | — | — | No | none | none | none | none | 0 | — | floor face &#124; wall face | 0 | removed | support removed | Floor + Wall faces (implicit) | Yes | One per face per tile; connects intakes to pumps | Wrench | Carries PumpableWater only; visually distinct from Water pipes |
| Water Intake | PumpableWater | Intake (Water) | — | — | PumpableWater | — | No | none | none | none | none | 0 | shoreline | inline | 1 | nonfunctional | support removed, time | Floor + shoreline | No | Adjacent to river/lake | Construction skill | Abstract intake point for environmental water sources |
| Drip Irrigation Pipe | Water | Pipe (Water, Irrigation) | — | — | — | Water | No | none | a little | none | none | 0 | — | floor face | 0 | removed | support removed | Floor faces (implicit) | Yes | Farm tiles only; area-of-effect coverage | Wrench | Emits water to nearby tiles; configurable range |
| House Water Boundary | Water | Boundary (Water) | — | — | Water | — | No | none | none | none | none | 0 | building wall | wall face | 1 | nonfunctional | support removed, time | Wall connection | No | One per house | Wrench | Boundary between outside network and interior usage |
| Large Wind Water Pump | Water | Pump (Water, Wind) | — | — | Water | — | No | a little | a little | a lot | a lot | 2 | clear space | floor face | 6 | reduced efficacy | time, exposure loss, damage | Floor connection (large footprint / structure) | No | Dedicated structure | Carpentry + Mechanics | High-capacity wind-driven water pumping; requires significant materials |
| Manual Water Pump | Water | Pump (Water, Manual) | — | — | Water | PumpableWater | No | a little | a little | none | some | 0 | — | inline | 0 | reduced efficacy | time, damage, power loss | Inline with Pumpable Water Pipe network; not required to be adjacent to intake | No |  | Mechanics | Manual transformer; refills internal buffer via player action (time + stamina); low throughput; no electricity |
| Small Wind Water Pump | Water | Pump (Water, Wind) | — | — | Water | — | No | a little | a little | some | some | 1 | clear space | floor face | 3 | reduced efficacy | time, exposure loss, damage | Floor connection (2–4 tile footprint) | No | Open area required | Carpentry + Mechanics | Passive water provider; output varies with wind; low but steady throughput |
| Water Pipe | Water | Pipe (Water) | — | — | — | — | No | none | none | none | none | 0 | — | floor face &#124; wall face | 0 | removed | support removed | Floor + Wall faces (implicit) | Yes | One per face per tile; obeys valve rules | Wrench | Pure topology element; visuals derived from adjacency (Base water transport; does not carry PumpableWater) |
| Water Pump | Water | Pump (Water, Powered) | — | — | Water | PumpableWater | Yes | a little | a lot | none | some | 0 | — | inline | 0 | reduced efficacy | time, damage, power loss | Inline with Pumpable Water Pipe network; not required to be adjacent to intake | No |  | Powered transformer; converts PumpableWater → Water. Contains an internal buffer with a refill rate. Requires electricity to refill; existing buffer may be drained when power is lost. Improves throughput and convenience but does not create access to water. |
| Water Tanker Hookup | Water | Hookup (Water) | — | — | Water | Water | No | a little | a little | none | none | 0 | vehicle-docking point | inline | 1 | nonfunctional | support removed, time | Floor connection | No |  | Wrench | Static hookup point. Becomes active only when a compatible vehicle or trailer is explicitly docked by the player. While docked, temporarily exposes a Provider or Consumer backed by the vehicle’s tank; direction (fill vs drain) is player-selected. Inert when no vehicle is connected. |
| Water Valve | Water | Valve (Water) | — | — | — | — | No | none | a little | none | none | 0 | — | between two | 0 | removed | support removed | Exactly 2 surface connections | Yes | Must connect exactly two pipe surfaces | Wrench | Gating element; open/closed state |
---

## Water Pump Semantics (Authoritative)

Water pumps behave as **resource transformers**, not hard access gates.
They convert PumpableWater into usable Water within the pipe network.

### Core rules

1. **Water Intakes provide PumpableWater**
   - Rivers, lakes, and wells expose PumpableWater
   - PumpableWater may be transported via Pumpable Water Pipes

2. **Water Pumps consume PumpableWater and provide Water**
   - Pumps transform water; they do not create it
   - No PumpableWater → no Water

3. **Pumps contain an internal buffer**
   - Buffer refills at a defined rate
   - Buffer size limits instantaneous output

4. **Powered water pumps require electricity**
   - Without power, powered pumps cannot refill
   - Existing buffer may still be drained

5. **Manual water pumps exist**
   - Manual pumps do not require electricity
   - Refill requires player time and stamina
   - Throughput is intentionally low

6. **Pumps improve convenience, not access**
   - Water may still be gathered manually without pumps
   - Pumps exist to enable automation and scale

### Design intent

This hybrid model preserves Project Zomboid expectations:
- Water is physically present and accessible
- Infrastructure increases efficiency, not capability
- Manual labor can substitute for power at small scale

Water pumps therefore differ intentionally from fuel pumps, which act as strict access gates.


## Fuel Pump Semantics (Authoritative)

Fuel pumps do **not** behave like generic Providers.
They are **resource activators** that gate access to otherwise inaccessible storage.

### Core rules

1. **Gas Station Storage is never directly connectable**
   - It does not expose Fuel to the network
   - It exists only as an implicit backing store

2. **Fuel Pumps pull from Gas Station Storage**
   - Pumps refill an internal buffer from storage
   - If storage is empty, pumps cannot refill

3. **Fuel Pumps provide Fuel only from their buffer**
   - No buffer → no Fuel
   - Pumps do not provide infinite throughput

4. **Electricity gates pump operation**
   - Powered pumps require electricity to refill
   - Without power, powered pumps are inert

5. **Manual Fuel Pumps bypass electricity at a cost**
   - Manual pumps have very small buffers
   - Refill requires player time and stamina

6. **Pumps do not push Fuel**
   - Consumers (barrels, tankers, generators) pull from pumps
   - This enables filling containers without exposing storage

7. **Pump count is limited per storage**
   - Typically one powered pump per gas station
   - Prevents throughput multiplication exploits

### Design intent

This model preserves vanilla Project Zomboid intent:
- Fuel is difficult to access
- Power matters
- Pumps are visible choke points
- Storage is not trivially exploitable

It also avoids introducing a separate `PumpableFuel` resource while maintaining gameplay integrity.




## Windmill Semantics (Authoritative)

Windmills are **passive Providers** whose available output is a function of environmental conditions rather than fuel, electricity, or player action.

### Core rules

1. **Windmills consume no resources**
   - No fuel, electricity, or PumpableWater is required
   - Output is entirely environment-driven

2. **Available output varies with wind**
   - Wind strength directly affects provider availability
   - Calm conditions may reduce output to zero

3. **Windmills provide limited, non-burst throughput**
   - No large internal buffers
   - Output accrues gradually over time

4. **Placement is constrained**
   - Must be placed outdoors
   - Surrounding obstructions may reduce or eliminate output

5. **Size matters**
   - Small windmills provide minimal output suitable for localized needs
   - Large windmills require significant construction and provide substantially more output

6. **Water and electricity windmills are distinct**
   - Water windmills provide Water directly
   - Electrical windmills provide Electricity directly
   - No transformation between resources occurs within the windmill itself

### Design intent

Windmills represent long-term, maintenance-free infrastructure:
- They reward survival longevity and planning
- They introduce weather-driven variability
- They provide alternatives to fuel- and power-dependent systems without replacing them

Windmills are intentionally inefficient compared to fuel or electric generators but offer sustainability and resilience.

---

## Tanker Hookup Semantics (Authoritative)

Tanker hookups are **static interaction points**, not proximity-based adapters.

### Core rules

1. **Hookups are inert by default**
   - No resource flow occurs without a docked vehicle or trailer
   - Hookups do not scan nearby tiles or vehicles

2. **Vehicles are explicitly docked**
   - The player must align and initiate a docking action
   - Docking mirrors refueling and trailer hitch mechanics

3. **Docking injects temporary capabilities**
   - While docked, the hookup temporarily exposes a Provider or Consumer
   - The backing storage is the vehicle or trailer’s tank
   - Flow direction (network → vehicle or vehicle → network) is player-selected

4. **Undocking removes capabilities immediately**
   - Removing the vehicle instantly disables the hookup
   - Any in-progress transfer is aborted safely

5. **No implicit access to vehicle storage**
   - Vehicles are never treated as part of the network
   - The hookup is the sole interaction boundary

### Design intent

This model prioritizes clarity and performance:
- No polling or proximity checks
- No ambiguous connections
- Clear player intent and feedback

Tanker hookups behave like wall sockets for vehicles: visible, explicit, and inert until used.

## Provider Availability Invariant (Authoritative)

All Providers in this system expose a **dynamic available amount** for each resource they provide.

### Invariant

- A Provider must be able to answer:
  > **"How much of resource X can I provide *right now*?"**

- This value:
  - may change over time
  - may be bounded by an internal buffer
  - may depend on refill rates, power, fuel, stamina, or inventory state

- **Consumers and allocation logic operate exclusively on this available amount.**
  - Consumers do not inspect storage, fuel sources, or refill mechanisms directly
  - Consumers never "push" resources; they always pull

### Implications

- Pumps, generators, battery banks, and similar entities are unified as Providers
- Storage, refill, and gating logic are encapsulated entirely within the Provider
- Allocation remains resource-agnostic and implementation-independent

This invariant is foundational to the flow system and must be preserved by all future Providers.

---