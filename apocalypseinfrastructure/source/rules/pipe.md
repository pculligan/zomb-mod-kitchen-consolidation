# Pipe

## What the Player Does

> “Attach a pipe to this surface.”

That is the **only** choice the player makes.

---

## Faces

A pipe attaches to **one face**:
- floor
- north / east / south / west wall

Other faces of the same cell remain available.

---

## Placement Rules

A pipe may be placed if:
1. A face is selected
2. No other attachment exists on `(cell, face, resource)`

A pipe **does not require neighbors** to exist.

---

## Connectivity (Derived)

Connectivity is automatic:

### Floor
- connects N/E/S/W on same Z

### Walls
- connects only along same wall face

### Vertical
- if same face exists on adjacent Z → vertical continuity

There is no explicit vertical pipe.

---

## Visuals

Pipe visuals are derived from:
- resource
- face
- 4-bit connectivity mask

Players never select pipe shapes.

---

## Interaction with Valves

- Pipes never gate flow
- Valves gate exactly one face-level connection
- Pipes may bypass valves via other faces

This is intentional and visible.

---

## Design Principle

> **Pipes express intent;  
> connectivity is derived;  
> visuals are authoritative.**