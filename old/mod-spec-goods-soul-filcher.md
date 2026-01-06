# SoulFilcher Compatibility Specification (Phase 1)

This document describes how the **Combine Food** mod interacts with items
defined by **SoulFilcher’s CookingTime** mod.

This is a **best-effort compatibility specification**, not a guarantee of
complete or future support. Compatibility is determined strictly by the
rules of Combine Food Phase 1, not by the design intent of CookingTime.

---

## Purpose

The goal of this document is to:

- Explicitly document which SoulFilcher items are supported in Phase 1
- Explain *why* certain items are included or excluded
- Prevent scope creep and accidental Phase-2 behavior
- Provide a reference for contributors and bug reports

This document is **non-normative**.  
Authoritative behavior is defined in Lua data modules.

---

## Compatibility Principles

SoulFilcher items are supported **only if they already conform**
to the Phase-1 eligibility rules of Combine Food.

No special-case logic is introduced for third-party items.

### An item MAY be supported if:

- `Type = Food`
- Consumption is **portion-based**, not `Type = Drainable`
- The item represents a **fungible quantity**
- The item is **not a prepared dish**
- The item is **not raw or dangerous meat**
- Container behavior can be expressed using existing byproduct rules
  (tin can, jar, bottle, sack, etc.)

### An item is NOT supported if:

- `Type = Drainable`
- `Alcoholic = TRUE`
- Uses `CustomContextMenu = Drink`
- `DangerousUncooked = TRUE`
- Replaces on use with **cookware** (pots, bowls, trays)
- Represents a cooked or prepared dish
- Represents a discrete food object (plants, fruits, slices, meals)

---

## Supported SoulFilcher Items (Phase 1)

Only the items listed below are intended to be supported.

Support is **explicit**, not inferred.

---

### Containerized Foods (Byproduct Preserved)

These items behave like opened cans or jars:  
their contents are fungible, and a physical container is preserved
when fully consumed.

| Display Name | FullType | Byproduct | Notes |
|-------------|----------|-----------|------|
| Opened Canned Ham | `filcher.CannedHamOpen` | `Base.TinCanEmpty` | Portion-based, cooked |
| Opened Canned Soup | `filcher.CannedSoupOpen` | `Base.TinCanEmpty` | Not drainable |
| Open Canned Spaghetti | `filcher.OpenCannedSpagetti` | `Base.TinCanEmpty` | Portion-based |
| Open Canned Spinach | `filcher.OpenCannedSpinach` | `Base.TinCanEmpty` | Fungible canned veg |
| Opened Cat Food | `filcher.SFCatfoodOpen` | `Base.TinCanEmpty` | Bulk pet food |
| Open Jar of Chocolate Wafer Sticks | `filcher.SFChocolateWaferSticksJarOpen` | `filcher.JarAndLid` | Jar semantics |
| Pickles (Jar) | `filcher.SFPickles` | `filcher.JarAndLid` | Jarred preserved food |
| Jelly (Jar) | `filcher.SFJelly` | `filcher.JarAndLid` | Fungible jarred spread |
| Tomato Sauce (Jar) | `filcher.SFTomatoSauce` | `filcher.JarAndLid` | Jarred sauce |

---

### Fungible Bulk Foods (No Byproduct)

These items are treated as **pure quantities** and do not yield a container
when consumed.

| Display Name | FullType | Notes |
|-------------|----------|------|
| Macaroni | `filcher.Macaroni` | Bulk dry staple |
| Bread Crumbs | `filcher.BreadPieces` | Fungible ingredient |
| Hazelnut Cream | `filcher.SFHazelnutCream` | Spread-like quantity |
| Sliced Potato | `filcher.SFPotatoSliced` | Pre-processed vegetable slices |
| Beans | `filcher.SFBeans` | Bulk cooked beans |
| Cinnamon | `filcher.Cinnamon` | Processed seasoning |
| Paprika | `filcher.SFPaprika` | Processed seasoning |
| Curry Powder | `filcher.SFCurry` | Processed seasoning |

---

## Explicitly Excluded SoulFilcher Items

The following categories are **intentionally excluded** in Phase 1.

This list is representative, not exhaustive.

### Drainables
- Corn batter (`Type = Drainable`)
- Drinkable batters
- Any item using `UseDelta`

### Alcohol & Drinkables
- Alcoholic beverages
- Glasses, cups, drinks
- Items using `CustomContextMenu = Drink`

### Prepared Dishes & Cookware
- Pizzas, cupcakes, soups, stews
- Pots, saucepans, trays, bowls
- Items that replace on use with cookware

### Raw or Dangerous Meat
- Items with `DangerousUncooked = TRUE`
- Raw meat and fish
- Cook-state-dependent foods

### Discrete Food Objects
- Fruits and vegetables (whole or sliced)
- Herbs and plants
- Popsicles, slices, single servings

These items require different semantics and are deferred to future phases.

---

## Non-Guarantees

- No guarantee of compatibility with future versions of CookingTime
- No attempt to support all SoulFilcher items
- No promise that unsupported items will be added later
- No override of CookingTime’s intended mechanics

---

## Future Phases

Items that may be considered in later phases include:

- Cook-state-aware meats and fish
- Foods with sickness or temperature semantics
- Items requiring more complex merge rules

Such support would require **new behavioral models**
and will not be added to Phase 1 retroactively.

---

## Summary

SoulFilcher compatibility in Phase 1 is:

- Explicit
- Rule-driven
- Conservative
- Non-magical
- Opt-in by behavior, not by mod affiliation

If an item fits the rules, it can be supported.  
If it does not, it is intentionally excluded.