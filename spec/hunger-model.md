

# Hunger Model (Authoritative)

This document defines the single, authoritative hunger model used by
**Kitchen Consolidation**. It exists to eliminate ambiguity caused by
Project Zomboid’s internal food fields and to clearly separate engine-owned
state from mod-owned invariants.

---

## Engine vs Mod Responsibilities

Kitchen Consolidation explicitly separates responsibility as follows:

### Engine-Owned State

The base game owns **current remaining hunger** for `Food` items.

- Accessed via `getHungChange()`
- Represents the amount of hunger that would be restored if the item were
  consumed immediately
- Reduced automatically by the engine when food is partially eaten or used
  in cooking (e.g., stews and soups)

The engine does **not** reliably preserve a canonical “full hunger” value
across item lifecycles.

Fields such as `BaseHunger` are treated as internal helpers and are not
considered authoritative or stable.

---

### Mod-Owned State

Kitchen Consolidation owns **maximum hunger capacity** for prepared and
fungible items.

- Stored explicitly on each prepared item instance as:

```
item:getModData().KC_FullHunger
```

- Assigned once at preparation time
- Never inferred later
- Never modified by consolidation or consumption
- Survives save/load and multiplayer replication

This value defines what “100% full” means for consolidation purposes.

---

## Canonical Definitions

For any prepared or fungible food item:

```
current = abs(item:getHungChange())
full    = item:getModData().KC_FullHunger
fraction = current / full
```

Where:

- `current` is engine-owned and mutable
- `full` is mod-owned and immutable

---

## Eligibility Rules

An item is eligible for consolidation if and only if:

```
0.0 < fraction < 1.0
```

Comparisons must use a small epsilon tolerance to account for floating-point
error.

Items with missing or invalid `KC_FullHunger` are **never** eligible for
consolidation.

---

## Why BaseHunger Is Not Used

Although item scripts may define `BaseHunger`, the field:

- Is not guaranteed to be initialized on spawned items
- Is not consistently preserved across item mutation
- May disagree with script-level values
- Cannot be relied on for deterministic math

Kitchen Consolidation therefore does not read from or write to `BaseHunger`
under any circumstances.

---

## Non-Drainable Food Model

Prepared items (e.g., Fish Pieces, Meat Pieces, Chopped Vegetables) use the
standard, non-drainable `Food` model:

- Partial consumption reduces `HungChange`
- The item remains until `HungChange == 0`
- No `UseDelta` or drainable semantics are involved

This matches vanilla behavior for apples, cabbage, fish fillets, and similar
foods.

---

## Consolidation Implications

Because consolidation relies on a mod-owned `KC_FullHunger`:

- Engine internals cannot invalidate consolidation math
- Multiplayer behavior remains deterministic
- Prepared items behave identically to vanilla food during cooking and eating
- Consolidation logic is independent of item script quirks

This model is intentionally simple, explicit, and conservative.

---

## Design Invariant (Non-Negotiable)

> **Kitchen Consolidation never infers “fullness” from engine fields.  
> All canonical fullness is captured once and stored explicitly.**

Any future feature must preserve this invariant.