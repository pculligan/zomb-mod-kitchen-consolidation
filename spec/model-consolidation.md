# Consolidation Model (Authoritative)

This document defines how **consolidation** works in Kitchen Consolidation.
Consolidation combines multiple partially consumed, fungible food items
(“Pieces”) into fewer items while **preserving total hunger exactly**.

This model is deterministic, conservative, and does not rely on engine
internals beyond current hunger.

---

## Purpose

Consolidation exists to:

- Reduce inventory clutter from many small partial items
- Restore usability in systems with limited ingredient slots
  (e.g., soups and stews)
- Preserve total hunger value exactly
- Avoid altering vanilla balance or consumption rules

Consolidation never creates or destroys food value.

---

## Eligible Items

Only **prepared fungible items** (“Pieces”) are eligible.

An eligible item must:

- Be a valid, non-drainable `Food`
- Have a valid `KC_FullHunger` value in `modData`
- Represent a partial amount of food

Eligibility condition:

```
0.0 < abs(item:getHungChange()) / KC_FullHunger < 1.0
```

Items with missing or invalid `KC_FullHunger` are never eligible.

---

## Grouping Rules (Strict Equivalence)

Items may be consolidated together **only** if they share all of the following:

- Item type (e.g., Fish Pieces vs Tomato Pieces)
- Cooked / uncooked state
- Burnt state
- **Freshness bucket** (fresh / stale / rotten)
- **Age progression fields** (`Age`, `OffAge`, `OffAgeMax`)
- Poison and sickness flags

Freshness is a *hard merge key*. Items in different freshness buckets are never consolidated together, even if all other properties match.

---

## Conservation of Hunger

Let:

```
total    = Σ abs(item:getHungChange())
capacity = KC_FullHunger
```

Then:

```
fullCount = floor(total / capacity)
remainder = total % capacity
```

This computation defines the outputs. No normalization or rebalance is applied.

---

## Output Generation

Consolidation produces:

- Zero or more **full Pieces items**
- Zero or one **partial Pieces item**

Each output item:

- Has the same `KC_FullHunger` as the inputs
- Has `HungChange` set to the appropriate remaining hunger
- Preserves all non-hunger state

### Example

- Five Pieces at 50% capacity
- Total hunger = 2.5 × capacity

Output:

- Two full Pieces
- One partial Pieces at 50%

---

## Freshness Preservation (Authoritative)

- Consolidation always preserves **worst-case freshness** among inputs.
- Output items inherit:
  - The maximum `Age` of all source items
  - The maximum `OffAge` of all source items
  - The maximum `OffAgeMax` of all source items
- `updateAge()` is invoked on all output items after state assignment.
- Consolidation is **never allowed** to improve freshness, reset rot timers, or normalize age values.

If any source item is stale or rotten, all consolidated outputs are at least that stale or rotten. Consolidation is conservative by design.

---

## Byproducts and Containers

If consolidation consumes items that emit byproducts when emptied
(e.g., cans or jars):

- Byproducts are emitted according to the number of source items consumed
- Container semantics are preserved
- No duplicate or missing byproducts are generated

Byproduct rules are item-specific and defined outside consolidation math.

---

## User Interaction

- Consolidation is **user-initiated** via context menus
- A consolidation option appears only when at least two eligible items exist
- Options are grouped by item type and state
- No automatic consolidation occurs

This ensures transparency and player control.

---

## Error Handling and Refusal

Consolidation refuses to proceed if:

- Any item lacks `KC_FullHunger`
- Items are not strictly equivalent
- Total hunger is zero
- Floating-point invariants are violated

Refusals are logged for diagnostics. No partial consolidation occurs.

---

## Explicit Non-Behavior

Consolidation does **not**:

- Infer “fullness” from engine fields (e.g., `BaseHunger`)
- Mix different food types
- Alter hunger balance
- Change how food is consumed
- Introduce drainable semantics
- Trigger automatically without player action
- Improve freshness, reset age, or bypass rot mechanics

---

## Design Invariant

> **Consolidation preserves total hunger exactly and never guesses.**

All future changes must preserve this invariant.