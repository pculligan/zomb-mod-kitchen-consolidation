# Kitchen Consolidation – Key Learnings (Build 41)

This document captures **non‑obvious engine behaviors and hard‑won lessons** discovered while building *Kitchen Consolidation* for **Project Zomboid Build 41**.  
These are things that are **not clearly documented**, easy to get wrong, and worth preserving for future work.

---

## 1. Build 41 Has Multiple, Independent Translation Domains

Build 41 does **not** have a single unified localization system. Instead, the engine recognizes **specific translation domains**, each with its own rules.

### Engine‑recognized domains (Build 41)

| Domain | Backing table / file | Used for |
|------|----------------------|---------|
| `ContextMenu_*` | `ContextMenu_EN` (Lua or txt) | Context menu labels |
| `IGUI_*` | `IGUI_EN` | Inventory / general UI |
| `ItemName_*` | `ItemName_EN.txt` | Item display names |
| `Tooltip_*` | `Tooltip_EN.txt` | Tooltips |
| `Recipes_*` | `Recipes_EN.txt` | Recipe text |
| `Sandbox_*` | `Sandbox_EN.txt` | Sandbox options |

**Important:** `getText()` only consults these known domains.  
Arbitrary tables or mismatched prefixes are silently ignored.

---

## 2. Prefix MUST Match Translation Table Name

For a translation to resolve via `getText()` in Build 41:

```
getText("ContextMenu_Foo")
```

**will only work if** the translation lives in:

```
ContextMenu_EN.ContextMenu_Foo
```

Likewise:

```
getText("IGUI_Bar")  → IGUI_EN.IGUI_Bar
```

This was the root cause of the long translation failure:
- `ContextMenu_EN` existed
- keys existed
- but were prefixed with `UI_*`, which `getText()` never consults in Build 41

Once keys were renamed to `ContextMenu_*`, translations resolved immediately.

---

## 3. Text‑file vs Lua‑table Translations in Build 41

Both **text files** and **Lua tables** can work in Build 41, *but only when they map to a known domain*.

Examples that work:

```
media/lua/shared/Translate/EN/ContextMenu_EN.txt
→ defines ContextMenu_EN = { ... }

media/lua/shared/Translate/EN/ItemName_EN.txt
→ defines ItemName_EN = { ... }
```

Lua‑based injection also works:

```lua
ContextMenu_EN = ContextMenu_EN or {}
ContextMenu_EN.ContextMenu_MyKey = "My Text"
```

What does **not** work:
- Custom tables with custom prefixes
- `UI_*` keys defined in Lua tables
- Assuming `getText()` will search arbitrary globals

---

## 4. Build 41 Does NOT Reliably Expose Language at Runtime

In many UI contexts (including inventory context menus):

- `getLanguage()` may be `nil`
- `getCore():getLanguage()` may be unavailable or unreliable

Translation logic in Build 41 should therefore be **static and defensive**:
- provide translations for all expected languages
- do not depend on runtime language detection

---

## 5. Food Nutrition Semantics Are Base‑Scaled, Not Remaining‑Scaled

This was a critical gameplay insight.

In Build 41:

- Food items store **base nutrition values**
- Displayed nutrition is effectively:
  ```
  baseNutrition × hungerFraction
  ```
- Calling `setHungChange()` causes the engine to **re‑normalize nutrition internally**

### Consequence for merging food

When combining partially eaten food:
- You cannot simply sum displayed calories
- You must:
  1. Sum **remaining nutrition**
  2. Compute the **merged hunger fraction**
  3. Back‑calculate **new base nutrition** so that:
     ```
     base × mergedFraction = totalRemaining
     ```

Failing to do this results in nutrition snapping back to the old base value (e.g. two half cans still showing 225 calories instead of 450).

---

## 6. Hunger and Thirst Are Negative‑Valued and Asymmetric

- Hunger and thirst values are **negative**
- More food = more negative
- Many Food items expose:
  - `setHungChange()` (correct)
  - but **not** `setHungerChange()`

Robust code must:
- preserve sign semantics
- prefer `setHungChange()`
- defensively check for method availability

---

## 7. Container Emission Must Be Tied to Actual Item Removal

When merging items:

- **Only items that are fully removed** should emit a container
- Partial absorbs must **not** emit containers
- Final remaining item must **never** emit a container

Invariant enforced in Kitchen Consolidation:

```
N input items → N − 1 containers
```

This avoids double‑emission bugs and “extra empty can” artifacts.

---

## 8. Debugging Strategy That Worked

What finally made progress possible:

- High‑signal debug logs (source state → result state)
- Logging **engine getters** rather than assumptions
- Verifying invariants (fractions, counts, totals)
- Comparing against known‑working mods instead of docs

This confirmed:
- where the engine re‑normalizes values
- which APIs silently fail
- which patterns are actually wired in Build 41

---

## 9. Single‑Result Merge Models Are Fundamentally Wrong for >1.0 Totals

Any consolidation model that mutates **one surviving item** is incorrect once the total remaining content can exceed a single “full” unit.

Examples that break single‑result logic:

- 5 × half cans → 2.5 units
- 3 × 0.75 cans → 2.25 units

Correct behavior requires **multi‑yield output**:

```
fullCount = floor(totalRemaining / fullUnit)
remainder = totalRemaining % fullUnit
```

This produces:
- `fullCount` fully full items
- `+1` partial item if `remainder > 0`

Attempting to shoehorn this into one result item leads to:
- content loss
- overfilled items
- or engine re‑normalization fighting your math

---

## 10. Full Items Must Be Preserved, Not Recreated

During consolidation:

- Items already at 100% fullness must be **left untouched**
- Only **partial items** should be consumed and merged

Failing to partition inputs leads to:
- destroying and recreating full items
- loss of freshness, sickness, age, and mod metadata
- subtle incompatibilities with other mods

Correct approach:

```
partition inputs → fullItems + partialItems
aggregate only partialItems
remove only partialItems
```

Full items remain in inventory as‑is.

---

## 11. Container / Byproduct Emission Is a Net Arithmetic Problem

Containers represent **net loss of containers**, not per‑item removal.

Correct invariant:

```
byproducts = consumedItems − producedItems
```

Where:
- `consumedItems = number of partial items removed`
- `producedItems = fullCount + (remainder > 0 ? 1 : 0)`

Examples:

| Partials | Produced | Empties |
|---------:|---------:|--------:|
| 2 × 0.5 | 1 | 1 |
| 3 × 0.5 | 2 | 1 |
| 4 × 0.25 | 1 | 3 |
| 1 × 0.5 | 1 | 0 |

Per‑item container emission is wrong whenever aggregation occurs.

---

## 12. EPS Must Be Used Everywhere Fractions Are Compared

Floating‑point noise causes subtle bugs if not handled consistently.

Rules:

- Never compare fractions directly to `0` or `1`
- Always use a shared epsilon (`Util.EPS`) when checking:
  - “is full”
  - “is remainder meaningful”
  - “should we spawn a partial”

Inconsistent thresholds lead to:
- ghost partial items
- extra containers
- off‑by‑one yields

---

## 13. UI Selection Policy Is Separate from Merge Correctness

Allowing full items to be selectable is **not a correctness bug** as long as:

- full items are filtered out before aggregation
- they are not removed
- they are not re‑emitted

Selection policy (what the UI allows) should be treated as a **separate concern** from merge correctness.

---

## 14. High‑Signal Debugging Was Essential

The final breakthrough came from logging **invariants**, not values:

- input fractions
- partition counts (full vs partial)
- aggregate math (`fullCount`, `remainder`)
- consumed vs produced counts

Logging these made it possible to reason about correctness **without relying on UI behavior**, which often lags or lies in Build 41.

---

## 15. Separate “Math” From “Inventory Mutation”

The design stabilized once responsibilities were split:

- **Pure math utilities**
  - fraction computation
  - aggregate yield calculation
- **Imperative action code**
  - remove items
  - add items
  - emit byproducts

Trying to mix these layers made bugs harder to reason about and easier to re‑introduce.

---

## Final Takeaway

Build 41 is **not forgiving**:
- many failures are silent
- multiple systems look similar but are not connected
- documentation often mixes pre‑41 and post‑41 behavior

When something “should work” but doesn’t:
1. Check the translation domain
2. Check the key prefix
3. Check which table `getText()` actually consults
4. Assume base‑scaled semantics for food and let hunger drive normalization

These lessons are now encoded in *Kitchen Consolidation* and should be reused verbatim for future Build‑41 mods.

---

## 16. Item Script DSL Is Not Lua (Booleans, Fields, and Silent Failure)

Project Zomboid item scripts use a **custom DSL**, not Lua. Common pitfalls:

- Boolean literals must be lowercase:
  ```
  true / false
  ```
  Uppercase `TRUE` / `FALSE` are invalid and can be interpreted as item names.
- Some fields that look boolean are actually **string item references** (e.g. `ReplaceOnUse`).
  Setting:
  ```
  ReplaceOnUse = false
  ```
  causes the engine to attempt to spawn `ModID.false`, leading to hard-to-diagnose crashes.
- The parser fails **silently**. Bad fields often manifest later as:
  - invisible items
  - null result items
  - crafting UI crashes

**Rule:** Only set fields that are required and documented; omit ambiguous ones.

---

## 17. EvolvedRecipe Is the Only Correct Way to Participate in Stews/Soups (Build 41)

Stews and soups are **not extensible via normal recipes or Lua hooks** in Build 41.

- Ingredient addition is driven by **EvolvedRecipe**, not `recipe {}` blocks.
- Valid participation requires:
  ```
  EvolvedRecipe = Soup:X;Stew:X
  ```
- **Trailing semicolons are fatal**:
  ```
  Soup:20;Stew:20;   ← creates an empty entry and crashes UI
  ```
- The system assumes a non-null `resultItem`; malformed entries crash deep in UI code.

**Rule:** Use `EvolvedRecipe` exclusively for stew/soup ingredients; never override vanilla recipes.

---

## 18. Preparation ≠ Consolidation (Absolute vs Base-Unit Math)

A critical distinction:

- **Consolidation** (Phase 1) merges items with the **same base hunger unit**
- **Preparation** (Phases 2–3) converts **discrete items into a different fungible form**

For preparation:
- **Never** use base-unit aggregation helpers
- **Always** sum **absolute remaining hunger**:
  ```
  total = Σ abs(item:getHungChange())
  ```
- Add that total directly to the prepared pile

Using base-unit math across different item types causes:
- zero-add bugs
- NaN/Inf fractions
- silent food loss

---

## 19. Context Menu Inputs May Contain Duplicate Item References

`worldobjects` supplied to context menus may include the **same InventoryItem object multiple times**.

Symptoms:
- “Two items” logged when only one exists
- Double-counting
- Double-removal

**Fix:** Deduplicate by **object identity** before processing:
```
seen[item] = true
```

This is mandatory for all bulk actions.

---

## 20. Single-Pile Semantics Avoid UX Leaks and Inventory Clutter

For fungible prepared items (FishPieces, MeatPieces):

- Maintain **one pile per inventory**
- Always add to the existing pile
- Do not split piles based on hidden state (age/poison/taint)

Hidden-state branching leaks information to the player (e.g., “why did it make two piles?”).

**Rule:** Apply worst-case state **after** aggregation; never fork piles to signal risk.

---

## 21. BYPRODUCT_ON_EMPTY Belongs to Preparation Actions, Not Policy Logic

Container byproducts (e.g., canned ham → empty can):

- Should be emitted **when the source item is removed**
- Should not be modeled as merge semantics
- Should be driven by a **policy table** (e.g., `Meats.BYPRODUCT_ON_EMPTY`)
- Must emit **exactly one** byproduct per consumed containerized source

Raw items produce no byproducts.

---

## 22. Icons: One Bad Character Can Make Items Invisible

Item icon rules are strict:

- Use:
  ```
  Icon = GroundBeef,
  ```
- Invalid field names (e.g., `Icon.`) or missing commas silently break rendering
- Broken icon definitions often result in **invisible dropped items**

**Rule:** Treat item script syntax as fragile; validate visually after changes.

---

## 23. Build 41 Event Availability Is Load-Order Dependent

Many `Events.*` entries are **not guaranteed to exist at file load time**.

- Calling `.Add()` on a nil event crashes
- Guarding avoids crashes but may skip registration

**Rule:** Prefer **item-script mechanisms** (e.g., `EvolvedRecipe`) over Lua hooks.
If hooks are required, register them in `OnGameStart`.

---

## 24. New Item Scripts Require New Saves (Reliably)

Changes to:
- `HungerChange`
- `EvolvedRecipe`
- `DangerousUncooked`
- `Icon`
- most item-script fields

are **not reliably applied to existing saves**.

Symptoms:
- base hunger reported as `0`
- nutrition missing
- Inf/NaN debug output

**Rule:** Start a **new save** after item script changes.

---

## 25. Accept Engine Float Drift; Do Not Fight It

Values like:
```
0.6399999856948853
```
are normal.

- Caused by float math + engine normalization
- Observed in vanilla items (butter, ground beef, lard)

**Rule:** Compare with EPS; do not “round” or normalize manually.

---

## 26. Separate Policy, Math, and Mutation

Stable architecture emerged only after enforcing these boundaries:

- **Policy**: what items are eligible (whitelists)
- **Math**: pure calculations (fractions, totals)
- **Mutation**: inventory changes (add/remove/emit)

Mixing these layers caused:
- abstraction drift
- hard-to-debug regressions
- repeated fixes

---

## 27. Data-Driven Whitelists Scale Better Than Predicate Logic

For preparation eligibility:

- Use **declarative source lists** (`SOURCES`)
- Aggregate compat modules additively
- Keep actions dumb

This pattern:
- avoids logic duplication
- enables mod compatibility
- mirrors successful Phase 1 structures

---

## 28. Development Workflow: Use Symlinks

For iterative mod development:

- Symlink the mod directory into `Zomboid/mods`
- Avoid copying files per test
- Restart the game for item script changes
- Reload world for Lua-only changes

This drastically reduces iteration time and error rate.

---

## 29. Prefer Minimal Surface Area

Repeatedly validated principle:

> The smallest mechanism that matches vanilla behavior is usually the correct one.

Avoid:
- recipe overrides
- clever hooks
- speculative abstractions

Lean on:
- hunger as quantity
- evolved recipes for cooking
- explicit preparation steps

---

## 30. Encode Lessons Immediately

Every time a non-obvious engine behavior is discovered:
- write it down
- encode it as a rule
- reference it in future phases

This document prevented multiple regressions and should be treated as a **living reference** for future Build-41 mods.
