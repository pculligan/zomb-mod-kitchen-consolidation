# Valve

## Purpose

A **Valve** is a controllable gate placed on a pipe attachment that allows the player to **open or close a single connection path** in a resource network (water, fuel, electricity, etc.).

From the player’s point of view, a valve is simple:

> “Put a valve here, between these two pipes, and decide whether flow is allowed.”

The Valve exists to give players **control**, not to force them to understand topology, graphs, or internal mechanics.


## High-Level Behavior (Player Mental Model)

- The player explicitly chooses **which surface** the valve is attached to  
  (floor valve vs wall valve, rotated to the desired face).
- A valve is attached to a **surface** (floor or a specific wall face).
- It connects **exactly two pipe attachments** on that surface.
- When **open**, flow passes through.
- When **closed**, flow is blocked *along that path*.
- If closing a valve doesn’t actually block anything (because there’s another route), the valve appears **inactive / bypassed**.

Players never need to think about:
- nodes
- networks
- adjacency graphs
- face masks
- “riser” vs “pipe” concepts

They only think in terms of **placing and toggling valves**.


## Valve States (UI & Feedback)

Valves have three visible states:

### 🟢 Open (Green)
- Valve is open.
- Flow is allowed along the two connected directions.
- Closing it **would** block flow.

### 🔴 Closed (Red)
- Valve is closed.
- Flow is blocked along the two connected directions.

### ⚪ Bypassed / Ineffective (Grey)
- Valve is open or closed, but **has no effect**.
- There is an alternate path around it.
- Closing it does not isolate anything.

This avoids footguns:
- The player is not prevented from placing the valve.
- Instead, the system **communicates usefulness visually**.


## Placement Rules (Player-Facing)

A valve **may be placed** if and only if:

1. The player selects a **specific surface**:
   - Floor  
   - Or a specific wall face (north, east, south, west)

2. That surface is currently unoccupied for the chosen resource.

3. On that surface, there are **exactly two connectable pipe attachments**  
   adjacent to the valve’s location.

This “exactly two” rule is the core invariant that makes valve behavior  
deterministic and intuitive.

### Important clarifications

- The two attachments:
  - may be straight, angled, or vertical relative to each other
  - do **not** have to be “opposite” in a floor-only sense
- Valves may connect **any two directions** on a surface.  
  “Corner valves” are valid and required, especially for wall and  
  vertical pipe runs.
- Valves do **not** replace pipes; they occupy a surface slot themselves.

If more than two connections would exist on that surface, placement is rejected to prevent accidental 3-way or 4-way gating.


## Surface Occupancy & Coexistence

A valve occupies **one surface of one cell** for a given resource.

Important rules:

- Only **one attachment** (pipe or valve) may exist per  
  `(cell, surface, resource)`.
- A valve does **not** occupy the entire cell.
- Other surfaces of the same cell may still host pipes, valves,  
  sources, or sinks for the same resource.

Examples:

- A floor valve and a wall pipe may coexist in the same cell.
- A wall valve on the east face does not affect the north, south,  
  west walls, or the floor.
- A pipe may bypass a valve by connecting on a different surface.

This preserves flexibility while preventing ambiguous topology.


## What a Valve Does *Not* Do

- A valve does **not** destroy networks.
- A valve does **not** remove pipes.
- A valve does **not** automatically force isolation.
- A valve does **not** affect other surfaces on the same tile.
- A valve does **not** prevent pipes from being placed around it.  
  If an alternate path exists, the valve becomes bypassed and  
  communicates this state visually.

A valve only gates **one specific surface-level connection**.


## Surface Model (Conceptual)

Surfaces are the key abstraction:

- **Floor surface**
- **Wall surfaces**: north, east, south, west

A valve always belongs to exactly **one surface**.

Examples:
- A valve on the floor gates floor-level connections.
- A valve on the east wall gates connections running along that wall.
- A vertical run on a wall is just connectivity across Z on the *same wall surface*.

Players never choose “vertical” explicitly — vertical flow is derived from adjacency.


## Connectivity & Flow (Derived Behavior)

Internally, the system derives behavior as follows:

- A valve connects **two directions on its surface**.
- When open:
  - adjacency links are present
- When closed:
  - those adjacency links are removed
- The rest of the network remains intact.

If an alternate route exists, the valve is considered **bypassed** and shown as such.


## Visual Representation

Valve visuals are selected based on:

- the surface the valve is attached to
- which two directions it connects
- whether it connects horizontally, vertically, or at a corner
- current state (open / closed / bypassed)

The player never selects a specific valve sprite.  
The system chooses the correct graphic automatically.


## Design Rationale (Why Valves Work This Way)

Valves are intentionally designed around **surface intent** rather than  
cell ownership.

This allows:

- Natural player actions (“valve on this wall”)
- Flexible construction without hidden restrictions
- Clear visual feedback instead of silent failure
- Deterministic behavior without forcing players to learn topology rules

The system enforces hard structural invariants, but communicates  
effectiveness visually rather than blocking creativity.


## Technical / Implementation Notes (Advanced)

> This section exists for maintainers and contributors.  
> Players do not need to understand any of this.

### Intent vs Derivation

- **Intent**: the valve is attached to a specific surface.
- **Derivation**:
  - which two directions it connects
  - whether it blocks flow
  - whether it is bypassed
  - what graphic to render

### Exact Placement Validation

A valve placement is valid if:

- `(x, y, z, resource, surface)` is unoccupied
- exactly **two** connectable attachments exist on that surface
- both attachments belong to the same resource network

No restriction is placed on angle or orientation.

### Bypassed Detection

A valve is bypassed if:

- removing its two adjacency links
- still leaves a path between the two sides via the network

This is equivalent to checking whether the valve is a **bridge edge** in the graph.

This check:
- runs only on topology mutation (attach/detach/open/close)
- never during rendering

### Performance Guarantees

- All connectivity is computed at topology-change time.
- Rendering reads cached connectivity only.
- No registry or graph queries occur during draw.


## Design Philosophy

> **Valves give control, not homework.**

The system:
- prevents the worst mistakes
- allows flexible construction
- communicates effectiveness visually
- never forces the player to learn internal abstractions

If a valve is useless, the UI tells the player.  
If it’s meaningful, the player can rely on it.

That’s the goal.