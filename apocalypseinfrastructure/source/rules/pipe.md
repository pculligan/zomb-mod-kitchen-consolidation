# Pipe

## Purpose

A **Pipe** is a surface-attached component that allows a resource (water, fuel, electricity, etc.) to flow through a network.

From the player’s point of view, a pipe is simple:

> “Put a pipe on this surface so the resource can flow through it.”

The player explicitly chooses **which surface** a pipe is attached to (floor or a specific wall face). Rotation or cursor position determines the chosen surface; the system handles the rest.

The player never chooses a specific pipe shape or orientation. The system automatically derives connectivity and visuals based on where pipes are attached.


## Player Mental Model

- Pipes are **attached to a specific surface** of a cell.
- Surfaces are:
  - the **floor** of a tile
  - the **walls** of a tile (north, east, south, west)
- Pipes automatically connect to adjacent pipes on compatible surfaces.
- Pipes automatically change appearance as connections are added or removed.

Players do not need to understand:
- adjacency rules
- networks
- nodes
- pipe shapes

They simply attach pipes where they want flow to occur.

- A pipe occupies only the surface it is attached to; other surfaces of the same cell may still host other attachments.


## Placement Rules (Player-Facing)

A pipe may be placed if:

1. The player selects a **surface** (floor or a specific wall face).
2. There is no other attachment (pipe or valve) already occupying that **same surface** for the same resource.

That’s it.

This means a floor pipe and a wall pipe may coexist in the same cell, but two attachments may never occupy the same surface slot.

Pipes do **not** require an existing connection to be placed. A single pipe by itself is valid.


## Connectivity (Derived Behavior)

Pipe connectivity is **fully automatic** and derived from adjacency:

### Floor Pipes

- Connect to other floor pipes in **cardinal directions** (north, east, south, west).
- Do not connect diagonally.

### Wall Pipes

- Connect to other wall pipes on the **same wall face**.
- Wall pipes on different faces do not connect.

### Vertical Connectivity

- Pipes do not explicitly declare “vertical” behavior.
- Vertical flow is not declared explicitly and does not require a special pipe type.

If pipes are attached to the same wall face on adjacent Z-levels, the system automatically derives vertical connectivity and renders an appropriate vertical segment.

Vertical pipes are therefore *not placed*; they are *revealed* by adjacency.


## Visual Representation

Pipe graphics are chosen automatically based on connectivity.

The system determines:
- which directions the pipe connects to
- whether it turns, continues straight, or branches
- whether it appears to run vertically

The player never selects a pipe sprite manually.


## Interaction with Valves

- Pipes do not block or gate flow by themselves.
- Valves may be placed between two pipes on the same surface.
- When a valve is closed, pipes remain visible but flow is blocked along that path.
- Pipes may be placed in ways that bypass an existing valve by using a different surface. When this happens, the valve remains visible but is shown as bypassed.

Pipes are passive components; control always comes from valves or other active devices.


## Technical Notes (Advanced)

> This section exists for maintainers and mod contributors.

### Intent vs Derivation

- **Intent**: the pipe is attached to one or more specific surfaces.
- **Derivation**:
  - adjacency
  - network membership
  - visual connectivity

Pipes never encode topology directly.

### Face-Based Model

Internally, each pipe caches render-ready connectivity for five faces:

- floor
- north wall
- east wall
- south wall
- west wall

Each face stores a bitmask indicating which directions are connected.

All face connectivity is computed at topology-change time (attach/detach) and never during rendering.

### Performance Guarantees

- Pipe placement and removal are rare events.
- Connectivity is computed once per change.
- Rendering performs only simple lookups.

This ensures stable performance even in dense pipe networks.


## Design Philosophy

> **Pipes express intent; the system derives structure.**

The goal is to let players build naturally—by attaching pipes to surfaces—while the system handles correctness, connectivity, and appearance automatically.

If a pipe looks connected, it *is* connected — no hidden rules, no special cases.
