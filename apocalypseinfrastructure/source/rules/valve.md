# Valve

## What a Valve Is

> “Put a controllable gate between these two pipe runs.”

---

## Player Intent

The player chooses:
- surface (floor or wall face)
- rotation (implicitly selecting two directions)

The system derives:
- which two paths are gated
- whether the valve is effective

---

## Placement Rules

A valve may be placed if:
1. The selected face is empty
2. Exactly **two** connectable pipe paths exist on that face

Angle does not matter.
Corner valves are valid.

---

## States

### Open (Green)
Flow allowed.

### Closed (Red)
Flow blocked along that path.

### Bypassed (Grey)
Flow still possible via alternate route.

Valves are **never illegal** because they are bypassed.

---

## Surface Model

A valve occupies **one face** only.

Other faces:
- may host pipes
- may bypass the valve
- do not invalidate it

---

## What Valves Do NOT Do

- Do not destroy networks
- Do not prevent placement elsewhere
- Do not affect other faces
- Do not enforce usefulness

They only gate one face-level connection.

---

## Technical Invariant

A valve:
- replaces exactly one adjacency edge
- never owns topology
- only toggles connectivity

All recomputation happens at mutation time.

---

## Philosophy

> **Valves give control, not homework.**

If it works, you see it.
If it doesn’t, you see why.