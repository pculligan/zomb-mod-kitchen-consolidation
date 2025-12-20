
```md
# Cooking Integration

This document describes how **Kitchen Consolidation** integrates with
Project Zomboid’s existing cooking systems, including soups, stews, and
other recipes.

The integration is intentionally minimal: Kitchen Consolidation relies on
vanilla consumption semantics rather than overriding or replacing recipes.

---

## Core Principle

> **Kitchen Consolidation does not modify how cooking works.**

Instead, it ensures that prepared “Pieces” items behave like ordinary
partial foods from the engine’s point of view.

As a result:

- Existing recipes continue to function unchanged
- Cooking skill effects are preserved
- Multiplayer behavior remains consistent
- Compatibility with other mods is maximized

---

## How Cooking Consumes Food

In vanilla Project Zomboid:

- Cooking recipes consume food by reducing `HungChange`
- The engine determines how much hunger is removed based on:
  - Recipe requirements
  - Cooking skill
  - Recipe type (e.g., stew vs soup)
- Partial food items are naturally supported

Kitchen Consolidation aligns with this model by ensuring that:

- Prepared Pieces items expose correct `HungChange`
- No alternative consumption logic is introduced

---

## Pieces in Soups and Stews

Prepared Pieces items can be added to soups and stews without any special
handling.

When a Pieces item is added to a cooking pot:

- The engine reduces its `HungChange` by the required amount
- If hunger remains, the item persists
- If hunger reaches zero, the item is removed

Kitchen Consolidation does not intercept or modify this behavior.

---

## Limited Ingredient Slots

Soups and stews have a limited number of ingredient slots.

One of the primary motivations for consolidation is to mitigate this limit:

- Many small partial items are difficult to use efficiently
- Consolidation merges them into fewer, larger Pieces
- Larger Pieces restore usability without changing total food value

This improves player experience without altering balance.

---

## Cooking Skill Interaction

Cooking skill affects how efficiently food is used in recipes.

Because Kitchen Consolidation preserves vanilla hunger semantics:

- Cooking skill bonuses apply normally
- Higher skill results in less hunger consumed per use
- Lower skill consumes more hunger

No special cases are introduced for prepared Pieces items.

---

## Partial Consumption Semantics

Prepared Pieces items are **non-drainable Food items**.

As such:

- Partial consumption reduces `HungChange`
- The item remains usable until `HungChange == 0`
- UI feedback matches vanilla behavior (e.g., half-used food)

This mirrors how apples, cabbage, and similar foods behave in the base game.

---

## No Recipe Overrides

Kitchen Consolidation intentionally avoids:

- Adding custom cooking recipes
- Overriding vanilla recipes
- Modifying recipe definitions
- Injecting custom consumption logic

This avoids conflicts and ensures broad compatibility.

---

## Compatibility with Other Mods

Because the mod relies on vanilla mechanics:

- Other cooking mods continue to function normally
- Mods that alter recipe behavior operate unchanged
- Prepared Pieces items behave like ordinary Food items

Kitchen Consolidation does not assume ownership of the cooking pipeline.

---

## Design Invariant

> **Cooking systems consume hunger; Kitchen Consolidation only manages how
> hunger is distributed across items.**

This invariant ensures clean composition with vanilla and modded cooking
systems.
```