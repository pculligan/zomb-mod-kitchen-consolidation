# Single Player vs Multiplayer Nutrition Numbers

This document explains a **known and intentional difference** between
single-player (SP) and multiplayer (MP) behavior when partial-use foods
are consumed in stews or soups.

This behavior was observed and validated during testing of Kitchen Consolidation,
but it is **vanilla Project Zomboid behavior**, not a bug introduced by the mod.


## Observed behavior

Example scenario:

- Two fish fillets at **–20 hunger each** are prepared into Fish Pieces  
  → Fish Pieces total: **–40 hunger**
- Fish Pieces added to a stew:
  - First add consumes **–20 hunger**
  - Second add consumes **~–11 hunger**
  - Remaining Fish Pieces: **~–9 hunger**

This exact sequence:
- behaves as expected in **single-player**
- produces a remainder in **multiplayer**


## Why this happens in multiplayer

In multiplayer, **the server is authoritative** over nutrition and recipe effects.

When an ingredient is added to an `EvolvedRecipe` (stews/soups), the server does **not**
subtract a fixed hunger value. Instead, it:

1. Treats the ingredient as a **nutrition bundle**
2. Normalizes consumption across:
   - hunger
   - calories
   - proteins
   - lipids
   - carbohydrates
3. Applies a **scaled subtraction** based on remaining nutrition
4. Clamps values to prevent negative nutrition or desynchronization

Once a partial-use item drops below a certain threshold, subsequent uses
may consume **less than the nominal recipe amount**.

This produces small remainders such as –9 instead of clean multiples of –20.


## Why single-player looks different

In single-player:
- client and server logic are unified
- fewer reconciliation and clamping steps occur
- hunger subtraction often appears as fixed steps

Multiplayer must enforce stricter consistency guarantees to prevent
duplication or desync between clients.


## Why this is not a bug

This behavior already exists in vanilla multiplayer with items such as:

- ground beef
- butter
- lard
- margarine
- cooking oil

Kitchen Consolidation preserves this behavior intentionally.

Attempting to force exact hunger decrements in multiplayer would require:
- overriding `EvolvedRecipe` behavior
- server-side hooks
- manual hunger mutation

All of these would:
- diverge from vanilla semantics
- risk desynchronization
- break compatibility with other mods


## Design decision

Kitchen Consolidation **does not attempt to “fix” this discrepancy**.

The mod’s design goals prioritize:
- correctness relative to vanilla behavior
- multiplayer safety
- nutrition consistency

Small remainders in multiplayer are accepted as the correct outcome.


## Optional cosmetic mitigation (not implemented)

It is possible to make the remainder less noticeable by:
- adjusting base hunger values slightly (e.g. –25 instead of –20)

This does **not** change the underlying behavior and was not adopted to
avoid unnecessary balance changes.


## Summary

- Single-player often shows clean hunger decrements
- Multiplayer may show scaled decrements and remainders
- This is **vanilla Project Zomboid behavior**
- Kitchen Consolidation preserves it intentionally

If this behavior is observed in multiplayer, it should be treated as
expected, not as a defect.
