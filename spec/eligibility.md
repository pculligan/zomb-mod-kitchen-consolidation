# Eligibility Rules (Authoritative)

This document defines which items are eligible for **preparation** and
**consolidation** in Kitchen Consolidation. Eligibility is intentionally strict
to avoid ambiguity, exploits, and unintended gameplay changes.

---

## Two Distinct Eligibility Phases

Kitchen Consolidation applies eligibility rules in two separate phases:

1. **Preparation Eligibility**  
   Determines whether an item can be converted into a fungible “Pieces” form.

2. **Consolidation Eligibility**  
   Determines whether prepared Pieces items can be merged together.

These phases have different requirements and must not be conflated.

---

## Preparation Eligibility

An item is eligible for preparation if and only if all of the following are true:

- The item is a valid `Food` item
- The item is explicitly supported by a preparation mapping
- The item represents a discrete food source (not already fungible)
- The item is not excluded by non-goals or safety rules

Preparation is **opt-in**, never implicit.

### Examples of Preparation-Eligible Items

- Fish fillets
- Raw meat cuts
- Whole vegetables (e.g., cabbage, tomato, potato)
- Other discrete food items explicitly mapped to a Pieces type

### Explicitly Ineligible for Preparation

The following are **never** eligible for preparation:

- Items already in Pieces form
- Prepared meals (soups, stews, salads)
- Baked or crafted foods with complex recipes
- Non-food items
- Liquids and drainable containers
- Items not explicitly mapped

---

## Consolidation Eligibility

Only **prepared Pieces items** may be consolidated.

An item is eligible for consolidation if and only if:

- The item is a non-drainable `Food`
- The item has a valid `KC_FullHunger` value stored in `modData`
- The item represents a partial amount of food

Formally:

```
0.0 < abs(item:getHungChange()) / KC_FullHunger < 1.0
```

Items missing `KC_FullHunger` are never eligible.

---

## Strict Equivalence Requirement

Even if two items are individually eligible, they may only be consolidated
together if they are **strictly equivalent**.

Strict equivalence requires matching:

- Item type (same Pieces type)
- Cooked / uncooked state
- Burnt state
- Freshness / rot state
- Poison and sickness flags

No equivalence inference or normalization is performed.

### Poison / Taint Handling Rationale

Poisoned or tainted state is **not** part of the merge key.

Rationale:
- Poison and taint are *destructive* states: mixing any poisoned input must poison the output.
- Including poison/taint in the merge key would leak hidden information to the player
  (e.g., revealing that one item is poisoned because it fails to merge).
- Vanilla behavior treats poison as a contaminant, not a categorical type.

Behavioral rule:
- If any consolidated input is poisoned or tainted, the output is poisoned/tainted.
- Consolidation never removes or mitigates poison.

---

## State Sensitivity

Eligibility is sensitive to state, not just item identity.

For example:

- Fresh and stale items cannot be consolidated together
- Poisoned and clean items cannot be consolidated together
- Cooked and uncooked items cannot be consolidated together

This prevents hidden state transfer and preserves player expectations.

---

## Refusal Semantics

Kitchen Consolidation prefers **explicit refusal** over best-effort behavior.

If any eligibility condition is violated:

- The action is not offered in the UI
- The consolidation or preparation does not proceed
- A diagnostic log entry may be emitted

No partial or degraded behavior is attempted.

---

## What Eligibility Explicitly Does NOT Do

Eligibility rules do **not**:

- Guess intent
- Infer compatibility
- Normalize state
- Override vanilla restrictions
- Auto-convert items
- Apply fuzzy matching

All eligibility is rule-based and explicit.

---

## Design Invariant

> **If eligibility is unclear, the item is not eligible.**

This invariant protects both gameplay balance and implementation correctness.
