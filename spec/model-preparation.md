

# Preparation Model (Authoritative)

This document defines what **preparation** means in Kitchen Consolidation.
Preparation is the process by which discrete food items are converted into
fungible “Pieces” items that can later be consolidated, cooked, or consumed
partially.

Preparation is intentionally conservative and deterministic.

---

## Goals of Preparation

Preparation exists to:

- Convert multiple discrete food items into a single fungible form
- Preserve all vanilla consumption semantics
- Enable later consolidation without altering gameplay balance
- Avoid guessing or inferring engine-internal values

Preparation does **not** attempt to optimize, rebalance, or reinterpret vanilla
food behavior.

---

## What Preparation Produces

Preparation always produces one or more **Pieces** items.

A Pieces item is:

- A standard, non-drainable `Food` item
- Fungible with other Pieces of the same type
- Partially consumable using vanilla mechanics
- Compatible with soups, stews, and other cooking systems

Examples:

- Fish Fillet → Fish Pieces
- Meat → Meat Pieces
- Cabbage → Chopped Cabbage Pieces
- Tomato → Tomato Pieces

---

## Source Items

Preparation operates on one or more **source items**.

Source items must:

- Be valid `Food` items
- Be explicitly allowed by preparation rules
- Share compatible state (freshness, poison, cooked state, etc.)

Preparation never mixes incompatible sources.

---

## Canonical Hunger Assignment

The most important responsibility of preparation is assigning **maximum hunger
capacity** to the prepared Pieces item.

### Rule

> **Maximum hunger capacity is defined as the sum of remaining hunger across all
> source items at the moment of preparation.**

Formally:

```
KC_FullHunger = Σ abs(source:getHungChange())
```

This value is:

- Captured once, at preparation time
- Stored explicitly on the prepared item as:
  ```
  item:getModData().KC_FullHunger
  ```
- Never inferred later
- Never recomputed

This avoids reliance on engine fields such as `BaseHunger`.

---

## Current Hunger Preservation

Preparation preserves **current remaining hunger** exactly.

For each prepared Pieces item:

- The engine-owned `HungChange` field is set to the appropriate remaining value
- Partial hunger is preserved without modification
- Vanilla eating and cooking behavior remains unchanged

The engine remains solely responsible for reducing hunger during consumption.

---

## Multi-Output Preparation

When total source hunger exceeds the maximum hunger capacity of a single Pieces
item, preparation may produce multiple Pieces outputs.

Example:

- Three half items, each worth 5 hunger
- Total hunger = 15
- Pieces capacity = 10

Preparation yields:

- One full Pieces item (10 hunger)
- One partial Pieces item (5 hunger)

All outputs share the same `KC_FullHunger` value.

---

## State Preservation

Preparation preserves all relevant vanilla state:

- Freshness and rot
- Poison and sickness
- Cooked / uncooked state
- Nutrition values

No state is upgraded, downgraded, or normalized.

---

## What Preparation Explicitly Does NOT Do

Preparation does **not**:

- Modify engine hunger rules
- Alter how food is consumed
- Infer “full” values from engine fields
- Normalize hunger values across item types
- Mix incompatible food sources
- Introduce drainable food semantics

---

## Design Invariant

> **Preparation captures canonical fullness once and never guesses again.**

Any future preparation behavior must preserve this invariant.