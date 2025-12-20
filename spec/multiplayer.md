# Multiplayer Behavior (Authoritative)

This document defines how **Kitchen Consolidation** behaves in multiplayer
environments and the guarantees it provides. Multiplayer correctness is a
first-class requirement of the design.

---

## Core Principle

> **All game-affecting behavior occurs through server-authoritative timed actions.**

Kitchen Consolidation does not perform background processing, client-only
mutation, or speculative updates.

---

## Execution Model

All preparation and consolidation operations are executed as **timed actions**
that:

- Are initiated by the client
- Executed authoritatively on the server
- Replicated to all clients by the engine

This ensures that inventory changes, hunger updates, and byproducts are
deterministic and synchronized.

---

## Authoritative State

The following state is authoritative in multiplayer:

### Engine-Owned State

- Current remaining hunger (`getHungChange()`)
- Item existence and ownership
- Consumption during cooking and eating

### Mod-Owned State

- Maximum hunger capacity (`item:getModData().KC_FullHunger`)

`modData` is replicated by the engine and treated as authoritative server state.

No client-only fields influence consolidation math.

---

## Determinism Guarantees

Kitchen Consolidation guarantees that:

- The same inputs produce the same outputs on all clients
- Consolidation preserves total hunger exactly
- No rounding or normalization differs between clients
- Floating-point tolerance is applied consistently

No randomness is introduced at any stage.

---

## UI vs Authority Separation

The client UI:

- Detects potential eligibility
- Presents context menu options
- Dispatches actions

The server:

- Validates eligibility
- Performs all inventory mutation
- Computes consolidation math
- Emits byproducts

UI state is advisory only and does not determine outcomes.

---

## Conflict Handling

If multiplayer state changes between menu presentation and action execution
(e.g., another player consumes or removes an item):

- The server re-validates all invariants
- The action is safely refused if conditions are no longer met
- No partial or degraded behavior occurs

Refusals are logged for diagnostics.

---

## Byproducts in Multiplayer

Byproducts (e.g., empty cans or jars) are:

- Emitted by the server as part of the timed action
- Replicated automatically to all clients
- Never inferred or duplicated client-side

This prevents duplication exploits and desynchronization.

---

## Performance Considerations

Kitchen Consolidation is designed to be lightweight:

- No polling
- No background threads
- No per-tick processing
- Operations scale linearly with the number of items involved

Multiplayer performance impact is negligible.

---

## Compatibility with Other Mods

Because Kitchen Consolidation:

- Uses standard timed actions
- Respects vanilla consumption semantics
- Avoids recipe overrides

It composes cleanly with other multiplayer-safe mods.

Mods that alter hunger values or cooking behavior are respected without
interference.

---

## What Multiplayer Behavior Explicitly Does NOT Do

Kitchen Consolidation does **not**:

- Perform client-side authoritative logic
- Auto-consolidate items
- Bypass server validation
- Modify replication behavior
- Introduce new synchronization mechanisms

All behavior relies on existing engine systems.

---

## Multiplayer Invariant

> **If an operation cannot be validated safely on the server, it does not occur.**

This invariant preserves fairness, stability, and trust in multiplayer games.
