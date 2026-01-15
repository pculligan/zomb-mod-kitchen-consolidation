# Drip Irrigation & Resource Network System — Design Specification

This document defines **authoritative topology, placement, connector, and flow semantics**.
Rendering rules are defined in `ui.md`.

---

## 0. Ground Truth (Non-Negotiable)

- Every topology entity **must observe a real world object**.
- No sprite-only topology entities are allowed.
- Placement is **preview → commit**, never single-phase.
- Connectivity and sprites are derived **once**, cached, and never inferred during render.
- Context menus are resolved from **clicked square**, not mouse position.

---

## 1. Entity Model

An **Entity** represents *player intent* anchored to a world square.

Each entity:
- Observes a real `IsoObject` or equivalent
- Occupies one or more **faces** of a cell
- Is resource-typed
- Caches:
  - `attachedFaces`
  - `faceConnectivity[face] -> 4-bit mask`
  - `spriteByFace[face]`

Entities do **not**:
- scan neighbors during render
- infer connectivity dynamically
- encode “vertical” as a type

---

## 2. Faces & Intent

A cell `(x,y,z)` exposes exactly **five attachable faces**:

- `floor`
- `north`
- `east`
- `south`
- `west`

Player intent is expressed as:
> “Attach this entity to *this face*.”

Vertical behavior is **derived**, never explicit.

---

## 3. Pipes

Pipes:
- Attach to exactly one face
- Automatically connect to adjacent pipes on compatible faces
- May connect across Z if faces align

There is **no RiserPipe type**.

If two pipes exist:
- same face
- same resource
- adjacent in Z

→ vertical continuity is derived and rendered.

---

## 4. Valves

Valves:
- Attach to exactly one face
- Gate **exactly two** connectable paths on that face
- Default open (setting-controlled)
- Do not destroy topology
- May be bypassed

A valve:
- is valid even if ineffective
- communicates usefulness visually, not by rejection

---

## 5. Placement Lifecycle (Authoritative)

### Phase 1 — Preview

Preview returns:
- `valid: boolean`
- `reason: string (if invalid)`
- `attachedFaces`
- `faceConnectivity`
- `spriteByFace`

Preview is read-only.

### Phase 2 — Commit

Commit:
- requires observed world object
- creates entity
- registers topology
- updates neighbors

Preview and commit **must share codepaths**.

---

## 6. Context Menus

Context menus:
- Inspect the clicked square
- Enumerate existing entities
- Ask resolvers what actions are valid

Resolvers must:
- log why actions are offered
- log why actions are suppressed

Silent failure is a bug.

---

## 7. Flow Semantics

- Consumers request
- Providers fulfill
- Storage mutates only inside provider logic

Networks never mutate storage directly.

---

## 8. Debugging Guarantees

Every entity logs:
- INFO: attach / detach
- DEBUG: faceConnectivity changes
- WARN: recovered invalid states

A visual debug overlay is supported and recommended.

---

## 9. Philosophy

> **Players express intent.  
> The system derives structure.  
> The world explains itself visually.**