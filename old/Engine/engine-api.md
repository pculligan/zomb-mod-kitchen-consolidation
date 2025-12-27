# ZomboidEngine API Contract (AI-Facing)

## Purpose

`ZomboidEngine` is a **thin, procedural shim** between KitchenConsolidation mod logic and the unstable / inconsistent Project Zomboid Lua API.

It exists to:

- Contain engine weirdness
- Enforce the **one-call rule** at the mod layer
- Mirror **proven patterns** from working mods (e.g. SapphCooking)
- Avoid speculative abstraction, interpretation, or inference

**All KitchenConsolidation domain code must call through this API for engine interaction.**  
If a domain file needs engine state, it must use a shim getter.

This layer is **not** a domain model.
It is **not** a framework.
It is a **bag of sharp but predictable tools**.

---

## Global Rules (NON-NEGOTIABLE)

### 1. One-Call Rule
From mod code, **each concern must be expressible as a single call**.

Bad:
```lua
item:setCustomWeight(true)
item:setWeight(w)
assert(item:getWeight() == w)
```

Good:
```lua
ItemWeight.set(item, w)
```

All engine fan-out happens **inside** the shim.

### 1b. One-Call Applies To Reads
Domain code may not probe multiple engine getters.  
The shim provides single-call getters that internally handle engine method-name inconsistencies.

---

### 2. No Cross-File Logic Leakage
Each file owns exactly one concern.

- No file may “help out” another.
- No file may duplicate logic from another.
- No file may reach into another’s responsibility.

---

### 3. No Interpretation
The shim **does not guess intent**.

- No deriving hunger from weight
- No deriving weight from hunger
- No fallback heuristics beyond what working mods demonstrably do
- engine-method compatibility branching (e.g. getHungerChange vs getHungChange) outside the shim

If the engine exposes a setter, we call it.  
If it doesn’t, we log and move on.

---

### 4. Writes Are Authoritative
If the engine accepts a write call, **we trust it**.

We may:
- sanity-check with tolerance (floating point)
- log failures

We do **not** retry, infer, or “fix” engine behavior.

---

### 5. Guards Are About Validity, Not Policy
Guards only answer:
- “Is this call safe?”
- “Did the engine accept it?”

They do **not** encode business rules.

---

## Module Contracts

---

## `Item.lua` — Identity Only

**Purpose:**  
Minimal validation and identity access.

**Allowed:**
- `is / isValid`
- `raw`
- `fullType`

**Forbidden:**
- Mutation
- Engine calls beyond identity
- Food, weight, or inventory logic

**Mental model:**  
> “Is this even an item, and what is it?”

---

## `ItemWeight.lua` — Weight Mutation Shim

**Purpose:**  
Single authoritative place to **set and read item weight**, following SapphCooking patterns.

### Authoritative Behavior
- Weight is runtime state
- Always written explicitly
- Always written via `item:setWeight(value)`
- Optionally enables `setCustomWeight(true)` if present

Getter behavior is allowed to choose between engine weight getters strictly for compatibility:
- Prefer `getActualWeight()` when present
- Else fall back to `getWeight()`

This is not business logic; it is method-availability compatibility.

### API

```lua
ItemWeight.get(item) -> number | nil
ItemWeight.getActual(item) -> number | nil
ItemWeight.set(item, value) -> boolean
ItemWeight.copy(targetItem, sourceItem) -> boolean
```

### Copy Behavior

`ItemWeight.copy`:

- Reads runtime weight from `sourceItem` using the same compatibility logic as `get`
- Writes it to `targetItem` using `set`
- Performs no math, scaling, or inference
- Exists specifically to support “copy weight like SapphCooking” use cases

### Rules
- No script item inspection
- No registry lookups
- No hunger math
- No container math
- No secondary setters

### Validation
- `value` must be `> 0`
- Readback comparison uses epsilon tolerance only

**Mental model:**  
> “Make the engine believe this item weighs X.”

---

## `ItemFood.lua` — Food Mutation Shim

**Purpose:**  
Single-call setters for food-related engine properties.

### API

```lua
ItemFood.getHunger(item) -> number | nil
ItemFood.setHunger(item, value)

ItemFood.getBoredom(item) -> number | nil
ItemFood.setBoredom(item, value)

ItemFood.getUnhappiness(item) -> number | nil
ItemFood.setUnhappiness(item, value)

ItemFood.getPoisoned(item) -> boolean | nil
ItemFood.setPoisoned(item, boolean)

ItemFood.getAge(item) -> number | nil
ItemFood.setAge(item, age)

ItemFood.getOffAge(item) -> number | nil
ItemFood.setOffAge(item, value)

ItemFood.getOffAgeMax(item) -> number | nil
ItemFood.setOffAgeMax(item, value)

ItemFood.getCookState(item) -> "raw"|"cooked"|"burnt"|nil
ItemFood.getFreshness(item) -> "fresh"|"stale"|"rotten"|nil
```

### Getter Rules
- Getters may branch on method existence (`getHungChange` vs `getHungerChange`, etc.)
- Getters must not apply scaling or conversions beyond what is required to return the engine’s value in the same units the setter expects.
- If a value cannot be obtained safely, return `nil` and log a warn.

### Rules
- Mirrors working mod usage
- Uses engine setters directly
- No reads
- No math
- No validation beyond call safety

### Read APIs Are Allowed (For Domain Use)

FoodInstance and other domain code may need to *read* engine state.  
ItemFood.lua may provide getters that normalize **engine API inconsistencies only** (method name differences), without inferring meaning.

Examples:
- `ItemFood.getHunger(item)`
- `ItemFood.getAge(item)`
- `ItemFood.getCookState(item)`

**Mental model:**  
> “Tell the engine this food behaves like this.”

---

## `Inventory.lua` — Container Operations

**Purpose:**  
Safe, defensive interaction with inventory / containers.

### API

```lua
Inventory.is(inv) -> boolean
Inventory.add(inv, item) -> item | nil
Inventory.remove(inv, item) -> boolean
Inventory.contains(inv, item) -> boolean
Inventory.size(inv) -> Optional<number>
```

### Rules
- Supports engine naming inconsistencies (`AddItem` vs `addItem`)
- Uses `pcall` everywhere
- No assumptions about backing implementation

Inventory may provide small convenience read helpers (e.g. `Inventory.primary(player)`), but must not mutate items.

**Mental model:**  
> “Put things in, take things out, don’t crash.”

---

## `Engine.lua` — Convenience Aggregator

**Purpose:**
Single import point to avoid repetitive `require` calls.

### Rules
- **No logic**
- **No wrappers**
- **No behavior**

Pure re-export only.

### Exports
Engine should export the four shim modules:
- `Item`
- `ItemWeight`
- `ItemFood`
- `Inventory`

---

## Anti-Patterns (DO NOT DO THESE)

- Reintroducing `Optional.of` / `map` chains
- Reading ScriptItems for runtime behavior
- Deriving one engine property from another
- Creating new guard variants
- Abstract base classes / traits / mixins
- Rewriting files wholesale instead of surgical patches

---

## Success Criteria

When this spec is followed:

- Mod code makes **one call per concern**
- Engine quirks are contained
- Behavior matches known working mods
- No file “mysteriously” changes behavior later
- Debug logs are intelligible and localized

---

**This document is authoritative.  
If future patches contradict it, the patch is wrong — not the spec.**