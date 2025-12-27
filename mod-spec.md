# Kitchen Consolidation Mod Specification

## Purpose

In Project Zomboid, many canned foods become partially used during cooking/eating, producing items such as “Opened Can of X”. These items are typically **Food** items (not `DrainableComboItem`), so the base game offers **no native consolidation** mechanism like `ISConsolidateDrainable`.

This mod adds a **safe, deterministic, MP-compatible** way to consolidate partially used, fungible food items of the *same type* into fewer, fuller items while preserving realistic containers.

> **Naming Note**  
> This mod was originally conceived as “Combine Opened Cans.” As its scope expanded to include jars, sacks, bottles, bulk ingredients, and third-party food mods, it was renamed **Kitchen Consolidation** to better reflect its purpose.

## Goals

- Allow players to **combine partially used opened canned foods** into fewer, fuller items.
- Provide a **simple context-menu action** in inventory (similar UX to StackAll).
- Preserve **nutrition correctness** (calories/macros) to the extent deterministically possible.
- Avoid invasive changes to vanilla systems and maximize compatibility with other mods.
- Be safe for **multiplayer** (server-authoritative item changes via timed actions).
- Be explicit about limitations (spoilage/freshness edge cases, cooking state).

- Converting food into a true drainable item type.
- Supporting arbitrary food merges (e.g., soup + stew).
- Merging across different item types (beans + chili).
- Modifying vanilla cooking recipes or their consumption mechanics.
- Deep semantic interpretation of modded food scripts beyond deterministic data available on the item.
- Changing or eliminating empty container byproducts resulting from food consumption.
- Consolidating alcohol, beverages, or other drinkable items that already use vanilla drainable or container mechanics (e.g., bottles, cans, mugs).


## Unified Model: Preparation and Consolidation

Kitchen Consolidation operates on two distinct but complementary actions:

- **Preparation** — an explicit, irreversible step that converts a discrete food item
  into a prepared form.
- **Consolidation** — a deterministic merge of multiple partially used prepared items
  into fewer, fuller items of the same type.

These actions are intentionally separate and apply uniformly across supported foods.

---

## Preparation Model (Authoritative)

### Design Rule

**Prepared items preserve the same consumption semantics as their source item.  
The only added behavior is that prepared items are combinable.**

This rule ensures:
- vanilla cooking behavior is preserved
- cooking skill effects are preserved
- multiplayer behavior remains deterministic
- no artificial “unit” abstractions are introduced

Preparation never improves food quality, safety, or nutrition.

---

### Preparation Semantics

When an item is prepared:

- The resulting prepared item:
  - uses the same `Food` type and partial-use behavior as the source
  - preserves hunger, nutrition, freshness, sickness, and poison state
  - may be cooked, eaten, or used in recipes exactly like the source item
- Identity of the source item is discarded only at preparation time
- No automatic preparation occurs; all preparation is explicit

Examples:
- Fish fillet → Fish Pieces
- Raw meat cut → Meat Pieces
- Cabbage → Chopped Cabbage
- Potato → Chopped Potato

Prepared items differ from their sources only in name, icon, and combinability.

---

### Preparation Scope

Preparation applies to **discrete food items** that:
- are partially consumed by vanilla cooking
- produce unusable leftovers due to lack of combinability
- benefit from explicit processing

Examples include:
- fish fillets
- raw meat cuts
- whole vegetables (e.g., cabbage, potatoes)

Items already treated as fungible piles in vanilla (e.g., ground beef) are excluded.

---

## Consolidation Model (Authoritative)

### Design Rule

**Consolidation applies only to prepared items and other fungible quantities.  
Discrete source items are never consolidated directly.**

Consolidation preserves vanilla expectations by:
- merging only identical item types
- requiring identical cooked/burnt state
- requiring identical freshness state (default strict mode)
- preserving worst-case safety

---

### Consolidation Semantics

- Only prepared items (e.g., Fish Pieces, Meat Pieces, Chopped Vegetables)
  and other fungible foods (opened cans, dried beans) are eligible
- Consolidation:
  - reduces item count
  - never increases total quantity
  - never improves quality or safety
- Multi-yield consolidation rules apply deterministically

Prepared items behave identically to opened cans for consolidation purposes.

---

## Cooking and Recipe Integration

Prepared items participate in vanilla cooking systems without overrides.

- Stews and soups consume prepared items using:
  - the same partial-consumption logic as their source items
  - cooking skill–scaled consumption
- No recipe slot counts are changed
- No vanilla recipes are overridden

This preserves balance while allowing leftovers to remain usable.

---

## Multiplayer Guarantees

Kitchen Consolidation preserves vanilla multiplayer behavior.

- All inventory mutation occurs in timed actions
- Server remains authoritative
- Partial-consumption semantics are unchanged
- Minor numerical differences between SP and MP are accepted as vanilla behavior

No attempt is made to “fix” multiplayer normalization quirks.

---

## Non-Goals

This mod does **not** attempt to:
- merge discrete source items directly
- normalize food sizes or weights
- invent artificial portion units
- override vanilla cooking recipes
- force exact hunger decrements in multiplayer
- mix different prepared food types (e.g., mixed vegetables)

These concerns may be addressed by future features but are explicitly out of scope.

---

## Extension Path (Future Work)

This unified model supports future additions cleanly:

- Additional prepared vegetables
- Additional prepared meats or fish
- Optional mixed-preparation recipes (e.g., Mixed Vegetables)
- Sandbox toggles for strictness

All extensions must preserve the core rule:
**prepared items preserve source semantics; consolidation only reduces fragmentation.**

## Conceptual Eligibility Boundary

This mod intentionally operates only on **fungible food quantities**, not discrete physical food objects.

Alcoholic beverages and drinkable liquids are intentionally excluded from Phase 1. The base game already provides robust, well-tested mechanics for managing drinkable containers (e.g., bottles, cans, and other drainables), and this mod does not attempt to replace or duplicate that functionality.

### Fungible Quantity Foods (Eligible)

Eligible foods share the following characteristics:
- The item represents “some remaining amount of X,” not a distinct physical object
- Partial consumption is the primary lifecycle of the item
- Combining remaining portions does not create a new semantic entity
- Players already expect consolidation behavior to be safe and intuitive

Examples include:
- Opened canned or jarred foods
- Dried legumes (beans, lentils, split peas, soybeans)
- Processed bulk cooking ingredients and seasonings (e.g., flour, sugar, salt, oils, vinegars, syrups, powdered seasonings)
- Liquids and sauces that support partial consumption (oils, vinegar, honey, sauces)

These items are treated as interchangeable quantities, and merging them preserves player expectations.

### Discrete Object Foods (Explicitly Excluded)

The following categories are explicitly excluded, even if they technically support partial consumption:
- Whole vegetables and fruits (e.g., cabbage, potatoes, apples)
- Herbs, spices, flowers, and foraged plants (fresh or dried)
- Seeds, sheaves, hay, and agricultural bundles
- Fried foods and prepared dishes with identity
- Crafted or transformed foods where instance identity matters
- Botanical herbs and plants (fresh or dried), even when used as seasonings

For these items, merging would constitute **transformation or crafting**, not consolidation, and is therefore out of scope for this mod.

## Design Summary

### Recommended Approach
Implement **multi-yield virtual drainable consolidation** by:
- Treating each `Food` item’s remaining quantity as a **fraction** of its base hunger value.
- Partitioning inputs into **full** and **partial** items.
- Aggregating remaining quantity across **partial items only**.
- Producing **multiple output items**:
  - `floor(totalRemaining / fullUnit)` fully full items
  - `+1` partial item if a remainder exists.
- Preserving already-full items unchanged.
- Removing only partial items and emitting empty containers based on **net container loss**.

This is robust because it:
- Uses the game’s existing data model (`Food` items remain `Food`).
- Avoids dependency on base-game drainable consolidation actions.
- Minimizes desync risk (item add/remove is standard).

---

## Design and Architecture

This section describes the concrete folder layout, file responsibilities, and core functions. It is intended to be implementation-directive rather than illustrative.

### Folder Layout

```
media/
  lua/
    client/
      KitchenConsolidation_Context.lua
    shared/
      KitchenConsolidation_Util.lua
      KitchenConsolidation_Action.lua
      Translate/
        EN/
          CombineOpenedCans_EN.txt
        FR/
          CombineOpenedCans_FR.txt   (optional / future)
mod.info
```

### File Responsibilities

#### `Context.lua` (client)
Responsible for:
- Context menu injection via `Events.OnFillInventoryObjectContextMenu`
- Identifying eligible items using shared utility functions
- Grouping items by merge key (`fullType + cooked + burnt`)
- Creating and enqueueing timed actions
- No inventory mutation occurs in this file

#### `Util.lua` (shared)
Pure logic and deterministic helpers. No UI and no event hooks.

Responsibilities:
- Eligibility checks
- Quantity / fraction computation
- Grouping helpers
- Merge math (fractions, nutrition, weight)
- Worst-case freshness and sickness evaluation
- Empty container accounting

This file must be side-effect free except where explicitly returning merge plans.

#### `Action.lua` (shared)
Defines the timed action that performs the merge.

Responsibilities:
- Final validation of items still existing in inventory
- Executing the authoritative merge algorithm
- Removing source items
- Creating merged food items
- Creating empty container byproducts
- Applying nutrition, weight, freshness, and sickness results

All inventory mutations occur here.

#### Server-Side Code

No dedicated server-side Lua file is required for preparation or consolidation actions.

All inventory mutation occurs inside a timed action defined in shared code, which is authoritative and multiplayer-safe in both listen-server and dedicated-server environments.

A server-only Lua file may be introduced in the future if additional server-side validation, logging, or sandbox enforcement is required.

### Core Data Flow

1. Client context menu gathers selected items
2. Shared utilities filter and group eligible items
3. Client enqueues `ISKitchenConsolidationAction`
4. Timed action revalidates and executes merge on the authoritative side
5. Results (merged items + empty containers) are added to inventory

### Core Functions (Authoritative Contracts)

The following functions define the core contracts implied by this spec:

- `isEligibleFoodItem(item) -> boolean`
- `computeFraction(item) -> number`
- `buildMergeGroups(items) -> table`
- `computeBaseHungerAggregateYield(items) -> (fullCount, remainderFrac)`
- `applyWorstCaseFreshness(sourceItems, resultItem)`
- `applyWorstCaseSickness(sourceItems, resultItem)`
- `applyCappedWeight(sourceItems, resultItem)`
- `applyBaseHungerNutrition(sourceItems, resultItem)` *(legacy / transitional)*

Function naming may vary, but responsibilities must remain equivalent.

## User Experience

## Localization Policy

This mod is designed to be fully localization-safe.

Localization rules:
- All user-facing strings (e.g., context menu labels) must be retrieved via `getText()` using translation keys.
- No gameplay logic may depend on localized strings.
- Item names displayed in UI must be sourced from `item:getDisplayName()`, which is already localized by the base game.
- The mod must not attempt to derive logic from display names or translated text.
- English (`EN`) is the fallback language when no translation is available.

This ensures consistent behavior across all supported languages and prevents localization-related logic bugs.

### Context Menu
When player right-clicks inventory selection that includes eligible items:

- If selection contains **2+ mergeable items** of the same type:
  - Show: `Kitchen Consolidation (X)` where X is item display name (optional)
  - Optionally: `Kitchen Consolidation All` (bulk mode, groups by type)

### Output
- Resulting item appears in player inventory:
  - “Opened Can of Beans” (same type)
  - Representing combined remaining portion.
- Original items are removed.

### Optional Future UX
- Tooltip / confirmation dialog when items have mismatched states (freshness, spices, cooked flags).
- Bulk combine all by type, like StackAll.

---

## Eligibility Rules

### Base Eligibility (Deterministic)

An item is eligible for consolidation if all of the following are true:
- `instanceof(item, "Food")`
- `item:getFullType()` is present in the mergeable whitelist
- Remaining quantity fraction satisfies `0.0 < fraction < 1.0` (with epsilon tolerance)
- Item is not rotten
- Item is not frozen (optional; configurable)
- Item is not a container or composite item

These rules apply uniformly to all supported food classes, including prepared items.

### Mergeable Item Detection (Whitelist-Based)

This mod uses an explicit whitelist to determine which items are eligible for consolidation.

An item is considered a mergeable food item **if and only if** all of the following are true:
- `instanceof(item, "Food")`
- `item:getFullType()` exists in the mod’s mergeable whitelist
- The item’s remaining quantity fraction is strictly between `0.0` and `1.0` (see Quantity Model)

Detection is based exclusively on the item’s `fullType` identifier.
- Display names are never used.
- No pattern matching or heuristic detection is performed.

This guarantees deterministic behavior, multiplayer safety, and mod compatibility.

---

## State Compatibility Rules

Items can only be merged if they match on the following (configurable strictness):

### Required State Match

Items may only be consolidated if all of the following states match:
- Identical `fullType`
- Same cooked state
- Same burnt state

Freshness and food sickness risk are not considered for *eligibility*, but are applied conservatively during the merge process using worst-case rules.

### Optional match (configurable)
- Freshness / spoilage:
  - age / offAge / offAgeMax values (if accessible)
- Frozen state
- Tainted water flags (for liquids; probably not relevant to cans)

**Default mode**: strict by `fullType` and cooked/burnt.  
Freshness handling is tricky and may be a future enhancement.

---

## Consolidation Guarantees and Conservative Rules

Kitchen Consolidation intentionally adopts a *conservative realism* model. Consolidating food items never improves quality or safety; it only reduces fragmentation.

### Guaranteed Behaviors

The following behaviors are guaranteed:

- Deterministic consolidation based on identical `fullType`
- Hunger preservation using the authoritative fraction model
- Nutrition preservation (calories and macros) where deterministically accessible
- Freshness preservation using a **worst-case rule**
- Food sickness / taint preservation using a **worst-case rule** where detectable
- Weight preservation using a **capped weighted merge**

### Conservative Rules

The following conservative rules apply:

#### Freshness (Worst-Case Wins)
When consolidating items with freshness data:
- The consolidated item inherits the *worst* freshness state of any source item
- Freshness is never improved by consolidation
- If any source item is stale or near-rot, the consolidated item reflects that state

#### Food Sickness / Taint (Worst-Case Wins)
When sickness, poison, or taint flags are accessible:
- If any source item is flagged as risky, the consolidated item is flagged as risky
- Consolidation never removes or reduces food sickness risk
- If sickness flags are not deterministically accessible, behavior is unchanged

#### Weight (Capped Weighted Merge)
When weight values are accessible:
- Weight is combined proportionally using remaining fractions
- The resulting item weight is capped at the canonical weight of a full item
- The consolidated item can never exceed the encumbrance of a pristine full item

This prevents encumbrance exploits and preserves vanilla balance.

### Empty Container Byproducts

When consolidating food items that originate from containers (e.g., opened canned foods), the process produces empty container items as a byproduct.

Rules:
- Empty containers are produced based on **net container loss**, not per-item removal.
- The number of empty containers emitted is:

```
emptyContainers = partialConsumed − outputsCreated
```

- Newly created output items conceptually reuse containers.

Empty containers are added to the player’s inventory at the end of the timed action.
Empty containers are never merged, transformed, or suppressed by this mod.

This preserves vanilla material balance and prevents container loss during consolidation.

---

## Quantity Model

### Core Quantity Metric (Authoritative)

For a `Food` item, the remaining quantity fraction is defined as:

```
fraction = abs(food:getHungerChange()) / abs(food:getBaseHunger())
```

Rules:
- If `baseHunger <= 0`, the item is not eligible for consolidation.
- The fraction is clamped conceptually to the range `[0.0, 1.0]`.

An item is considered *partially used* **if and only if**:

```
0.0 < fraction < 1.0
```

Comparisons should be performed using a small epsilon tolerance to account for floating-point error (e.g., `EPS = 0.0001`).

Items with `fraction <= 0.0` or `fraction >= 1.0` are not eligible for consolidation.

### Merge Result Fraction
```
merged_fraction = min(fractionA + fractionB, 1.0)
remainder_fraction = (fractionA + fractionB) - 1.0  (if > 0)
```

Kitchen Consolidation uses **bulk aggregation**, not iterative pairwise merging:

```
totalRemaining = Σ remaining amounts
fullCount = floor(totalRemaining / fullUnit)
remainder = totalRemaining % fullUnit
```

This may produce multiple output items and is deterministic regardless of input count.

---

## Nutrition Preservation (Guaranteed Where Accessible)

### Deterministic Nutrition Merge
Most `Food` items expose:
- `getCalories()`, `getCarbohydrates()`, `getProteins()`, `getLipids()`

We can preserve totals by computing a weighted sum:

```
merged_calories = calA * fracA + calB * fracB
```

Same for macros.

### Hunger Change
```
new_hunger = -baseHunger * merged_fraction
```

(Using sign conventions to match existing item.)

### Weight
If item weight varies with remaining quantity:
- approximate weight scaling by fraction
- otherwise leave default weight

**Recommendation:** do not attempt to modify weight unless values are exposed and consistent. Many mods do weird things with weight.

Nutrition preservation is achieved implicitly via the multi-yield model.
Because nutrition in Build 41 is base-hunger–scaled, producing the correct number
of full and partial items preserves calories and macros without manually summing
nutrition into a single item. Single-result nutrition recomputation is intentionally
avoided.

---

## Multiplayer Safety

### Use Timed Actions
All inventory changes for preparation and consolidation should happen inside a timed action, even if instantaneous, to keep MP sync clean.

Recommended:
- Create `ISKitchenConsolidationAction` extending `ISBaseTimedAction`
- Set `maxTime = 0` or small duration (similar to StackAll’s zero-time approach)
- Perform:
  - validations
  - remove originals
  - add new item(s)

### Why timed actions matter
- Server authoritative inventory state
- Predictable replication to clients
- Avoids race conditions with UI state

---

## Events and Hooks

### Context Menu Hook
Use:

```lua
Events.OnFillInventoryObjectContextMenu.Add(function(player, context, items) ... end)
```

This is the standard inventory context injection point.

### Optional Hook: OnGameStart
For initializing mod options or constants:

```lua
Events.OnGameStart.Add(function() ... end)
```

---

## Mod Options / Sandbox Integration (Optional)

Provide settings to adjust strictness:

- `strict_type_match` (default true)
- `require_same_cooked_state` (default true)
- `consider_freshness` (default false)
- `allow_rotten_merge` (default false)
- `bulk_combine_all` (default true)

Implement via ModOptions (if present) or sandbox vars if you prefer server control.

---

## Data Structures (Suggested)

### Candidate grouping
During context menu build:

- group eligible items by `fullType`
- within each type group, further partition by cooked/burnt state

Example key:
```
key = fullType .. "|" .. cookedFlag .. "|" .. burntFlag
```

Then:
- if group size >= 2 → add menu option for that group
- optionally add “Combine All” across all groups

---

## Algorithm (Authoritative)
The following algorithm is the authoritative and mandatory behavior for consolidation:

1. Compute remaining fraction for each input item.
2. Partition inputs into **full** and **partial** items.
3. Aggregate remaining quantity across partial items only.
4. Compute output counts (`fullCount`, `remainderFrac`).
5. Remove partial items from inventory.
6. Spawn `fullCount` fully full items.
7. Spawn one partial item if `remainderFrac > EPS`.
8. Emit empty containers using:
   ```
   emptyContainers = partialConsumed − outputsCreated
   ```
9. Apply worst-case freshness, sickness, and capped weight to outputs.

---

## Edge Cases and Policy Decisions

### Items with zero base hunger
If `base == 0`:
- treat as non-mergeable
- log warning

### Items with missing nutrition methods
If macros/cals are nil:
- merge only hunger
- leave nutrition defaults
- or block merge depending on strictness
**Recommendation:** merge hunger only, keep macro merge best-effort.

### Freshness / Spoilage

Freshness is preserved conservatively using a worst-case rule.

When freshness data is accessible:
- The consolidated item inherits the worst freshness state of all source items
- Freshness is never averaged or improved
- If any source item is close to rotting, the consolidated item reflects that risk

This behavior is intentional and aligns with vanilla player expectations.

### Multiple outputs
In bulk mode, allow multiple outputs naturally from iterative merge.
In single selected merge, stick to one output by merging repeatedly.

---

## File Layout (Suggested)

```
media/lua/client/KitchenConsolidation_Context.lua
media/lua/shared/KitchenConsolidation_Util.lua
media/lua/shared/KitchenConsolidation_Action.lua
media/lua/shared/Translate/EN/CombineOpenedCans_EN.txt
mod.info
```

---

## Minimal Pseudocode

### Context menu detection (client)

```lua
local function isMergeableOpenedCan(item)
    if not instanceof(item, "Food") then return false end
    if not MERGEABLE_WHITELIST[item:getFullType()] then return false end

    local base = math.abs(item:getBaseHunger())
    if base <= 0 then return false end

    local cur = math.abs(item:getHungerChange())
    local frac = cur / base
    return frac > EPS and frac < (1.0 - EPS)
end

Events.OnFillInventoryObjectContextMenu.Add(function(player, context, items)
    local groups = groupEligible(items)
    for key, group in pairs(groups) do
        if #group >= 2 then
            context:addOption("Kitchen Consolidation", group, onCombine, player)
        end
    end
end)
```

### Timed action (shared)

```lua
ISKitchenConsolidationAction = ISBaseTimedAction:derive("ISKitchenConsolidationAction")

function ISKitchenConsolidationAction:perform()
    -- validate group still exists in inventory
    -- multi-yield merge loop
    -- remove partials, add merged items
    ISBaseTimedAction.perform(self)
end
```

---

## Testing Plan

### Functional tests
- Combine two half cans → one full can
- Combine 3 partial cans → correct number of outputs
- Mix cooked vs uncooked → option not offered (strict mode)
- Try non-opened cans → option not offered
- Verify no item loss/doubling

### Multiplayer tests
- Host dedicated server
- Two clients
- Combine items, ensure both clients see correct result
- Ensure no desync or invisible items

### Compatibility tests
- With common QoL mods
- With inventory transfer actions (backpacks)
- With modded canned foods (if whitelisted)

---

## Future Enhancements

- Smarter “opened can” detection from item scripts instead of name matching
- Freshness merge rules (weighted averages)
- UI showing “before/after” percentages
- Hotkey to bulk merge all eligible cans
- Report stats (how many items consolidated)

---

## Summary

This mod is:
- Deterministic and multiplayer-safe
- Conservative in balance and realism
- Explicit about guarantees and limitations
- Designed to consolidate convenience without improving food quality
- Structured for unified, explicit preparation and consolidation of food classes
- Enforces a clear conceptual boundary between fungible quantities and discrete food objects




