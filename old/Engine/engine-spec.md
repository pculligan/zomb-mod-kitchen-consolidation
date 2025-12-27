# ZomboidEngine Shim Specification (AI-Facing, Non-Negotiable)

This document exists to **lock behavior and prevent drift**.
It is written for an AI collaborator and must be treated as a **hard contract**.

If any code change conflicts with this document, the code change is wrong.

---

## Core Goal

Provide a **thin, stable shim** between mod code and the Project Zomboid engine APIs.

## Scope Clarification: Who May Touch the Engine

**Only the ZomboidEngine shim files may call Project Zomboid engine methods.**

- KitchenConsolidation domain code (e.g. FoodInstance, FoodRegistry, TimedActions, menu builders) must never call engine methods directly.
- Any engine read/write must be expressed as a one-call shim API call.

This is to prevent drift across engine versions and to keep all engine quirks localized.

### Primary Invariant

**Mod code makes ONE call.  
The shim makes ALL required engine calls.**

The mod must never:
- Call multiple engine methods for one logical operation
- Inspect engine version differences
- Perform defensive branching
- Reinterpret engine data
- Reproduce ugly engine call sequences

All chaos lives here.

---

## Source of Truth

When behavior is ambiguous or undocumented:

**Working mods (e.g. SapphCooking, FoodPreservationPlus) are the source of truth.**

Not:
- documentation
- wiki pages
- inferred intent
- “clean” API design
- historical behavior

If a working mod does something ugly and it works, **we copy it**.

---

## Files in Scope (Exactly Four)

Only these files participate in the shim:

1. `Item.lua`
2. `ItemWeight.lua`
3. `ItemFood.lua`
4. `Inventory.lua`

**Engine.lua remains a pure re-export convenience only.**
It may aggregate `require`s, but it may not add behavior.

No additional layers, helpers, facades, or abstractions are allowed.

---

## Shared Rules (Apply to All Files)

### 1. One-Call Rule

Each public function represents **one mod-level operation**.

Examples:
- `ItemWeight.set(item, weight)`
- `ItemFood.setHunger(item, value)`
- `Inventory.add(item)`
- `Inventory.remove(item)`

The caller must never:
- chain calls
- do math
- check method existence
- call getters first
- handle engine quirks

If an operation requires 3 engine calls, those 3 calls happen **inside the shim**.

**One-call applies to reads as well as writes.**
If FoodInstance needs hunger, it calls one shim getter (e.g. `ItemFood.getHunger(item)`), not 2–5 engine calls.

### 2. No Interpretation Layer

The shim does **not** infer meaning.

Forbidden:
- deriving weight from hunger
- deriving hunger from weight
- normalizing values
- inventing ratios
- caching engine state
- “smart” fallbacks
- engine-method compatibility branching (e.g. getHungerChange vs getHungChange) outside the shim

### 3. Guards Are Defensive Only

### 3a. No Lua `type()` Classification of Engine Objects (Critical)

**Never gate behavior based on `type(item)` for engine objects.**

Project Zomboid engine objects are frequently:
- proxied tables
- userdata
- hybrid table/userdata wrappers
- version-dependent representations

As a result, `type(item)` is **not a reliable signal** of validity.

#### Forbidden Pattern (Do Not Use)
```lua
if type(item) ~= "userdata" then return nil end
```

or any variation that attempts to classify engine objects via Lua `type()`.

#### Required Pattern (Duck-Typed Validation)

Validation must be based on **capability**, not Lua type.

Allowed examples:
```lua
if type(item.getAge) == "function" then ...
if type(item.getWeight) == "function" then ...
```

or guarded `pcall` usage.

#### Rationale (Hard-Learned Invariant)

Using `type(item)` caused **silent rejection of valid Food items**, blocking:
- FoodInstance.fromItem
- consolidation
- preparation menus

This failure mode is subtle, non-obvious, and version-sensitive.

**All engine-facing shims must assume userdata or proxy tables are valid unless proven otherwise by missing methods.**

This rule is non-negotiable.

Guards exist **only to prevent crashes**.

Allowed:
- `guardFail(x ~= nil, "...")`
- `guardWarn(item.setWeight, "...")`

Forbidden:
- inventing new guard types
- using guards to change behavior
- fallback logic that alters outcomes

Guards may log and return early.  
They must never reinterpret intent.

### 3b. No Guarded Engine Mutation Calls (Global Invariant)

**Invariant:**  
All engine *mutation* calls in **all ZomboidEngine shim files** MUST be made as **direct colon calls** with **no guards**.

This rule exists to eliminate a broken and misleading pattern that masks real engine failures and creates version‑dependent silent corruption.

#### Hard Rules (Non‑Negotiable)

For every engine mutation call in any ZomboidEngine shim file:

- **DO NOT** check `type(item.someMethod)`
- **DO NOT** use `pcall`
- **DO NOT** log and continue
- **DO NOT** attempt fallback setters
- **DO NOT** swallow engine errors

#### Required Pattern

All setters MUST be written as direct colon calls:

```lua
item:method(args)
```

No defensive branching is permitted around mutation calls.

#### Getters vs Setters

- **Setters (mutations):**  
  Must always be direct calls with no guards in all shim files.

- **Getters (reads):**  
  May perform minimal capability checks *only* to normalize engine API differences (e.g. `getHungChange` vs `getHungerChange`).  
  Getters must not mutate state, infer meaning, or add fallback behavior.

#### Rationale (Why This Is an Invariant)

The pattern:

```lua
if type(item.setX) == "function" then
    pcall(item.setX, item, value)
end
```

is **actively harmful** because it:

- Silently ignores real engine breakage
- Masks invalid call sites during development
- Produces inconsistent runtime state
- Encourages “log and limp on” behavior that corrupts food items

If an engine mutation call crashes, **that is correct behavior**.  
The crash surfaces a real incompatibility that must be fixed, not hidden.

#### Scope

- Applies to **all engine mutation calls**
- Applies to **all ZomboidEngine shim files**:
  - `Item.lua`
  - `ItemWeight.lua`
  - `ItemFood.lua`
  - `Inventory.lua`
- No shim file may guard, wrap, or suppress engine mutation calls

This invariant intentionally supersedes all prior defensive patterns (including `pcall`, capability checks, logging-and-continuing, or post-mutation verification) for engine mutation calls.

If an engine mutation crashes, that crash is **authoritative** and must be addressed at the call site or by updating the shim—not hidden.

This invariant overrides any prior examples that used guarded mutation calls.

---

## File-by-File Contract

---

## Item.lua

### Role

**Identity + validity wrapper only.**

### Responsibilities

- Hold a reference to a raw engine item
- Provide:
  - `isValid()`
  - `fullType()`
  - `raw()` (escape hatch)

### Explicitly Forbidden

- No setters
- No weight logic
- No food logic
- No inventory logic

### Mental Model

Item.lua answers:  
**“Do I have a thing, and what is it?”**

---

## ItemWeight.lua

### Role

**Single-call weight manipulation shim.**

### Responsibilities

- `get(item)` → return engine-reported weight
- `set(item, weight)` → set weight using **the exact pattern that works in real mods**

### Critical Rule

**Mirror SapphCooking behavior exactly.**

If SapphCooking does:
```lua
result:setWeight(item:getWeight())
```

Then we do that.

If it does:
```lua
result:setWeight(item:getWeight() * 0.7)
```

Then we do that.

No reinterpretation.

### Explicitly Forbidden

- Hunger math
- WeightFull / WeightEmpty models
- Registry involvement
- Multiple competing setters
- “Try everything” logic

### Mental Model

ItemWeight.lua answers:  
**“Set encumbrance the way mods that work already do.”**

---

## ItemFood.lua

### Role

**Single-call food property manipulation shim.**

### Responsibilities

Provide direct setters that map to engine calls used by working mods:

- `setHunger(item, value)`
- `setUnhappiness(item, value)`
- `setBoredom(item, value)`
- `setPoisoned(item, bool)`
- `setAge(item, age)` (if applicable)

### Read APIs Are Allowed (For Domain Use)

FoodInstance and other domain code may need to *read* engine state.
ItemFood.lua may provide getters that normalize **engine API inconsistencies only** (method name differences), without inferring meaning.

Examples:
- `ItemFood.getHunger(item)`
- `ItemFood.getAge(item)`
- `ItemFood.getCookState(item)`

### Rules

- Use the engine methods that working mods use
- No normalization
- No derived values
- No coupling to weight

### Explicitly Forbidden

- Touching weight
- Touching inventory
- Creating a “food model”
- Combining multiple properties into one abstraction

### Mental Model

ItemFood.lua answers:  
**“Set food properties using engine calls that actually work.”**

---

## Inventory.lua

### Role

**Item movement shim.**

### Responsibilities

- `add(container, item)`
- `remove(container, item)`
- Optional `transfer(from, to, item)` if required

### Rules

- Use engine inventory/container APIs directly
- Guards allowed to prevent crashes
- No item mutation logic here

Inventory may provide small convenience read helpers (e.g. `Inventory.primary(player)`), but must not mutate items.

### Explicitly Forbidden

- Weight logic
- Food logic
- Item spawning with side effects

### Mental Model

Inventory.lua answers:  
**“Put things places without crashing.”**

---

## What This Is NOT

- Not a framework
- Not a domain model
- Not OO design
- Not traits or mixins
- Not clean or elegant

It is **damage control**.

---

## Drift Prevention (AI Rules)

If you (the AI) are about to:
- add a new helper file
- reinterpret engine values
- refactor for elegance
- introduce readers/writers again
- invent new guards
- add math not seen in a working mod

**STOP.**

Re-read this document.  
Match a working mod.  
Implement the ugly thing once.  
Expose one call.

---

## Definition of Done

- Mod code makes one call
- That call works in-game
- No other file knows engine quirks
- These files are not touched again unless:
  - the engine breaks them
  - a working mod demonstrates a better pattern
# 
# AI Invocation Contract (Minimal Prompt)
#
## AI Invocation Contract (Minimal Prompt)

This section exists to eliminate verbose prompts and prevent drift.

Any AI working on this codebase must treat THIS FILE as the primary source of truth
and re-read it before making changes.

### Approved Minimal Prompt

The user may invoke work using the following short prompt:

“Follow ZomboidEngine/spec.md exactly.
Re-read it before making changes.
Patch only <FILE_NAME>.
One-call rule applies.”

No additional intent, explanation, or restatement is required.

### AI Obligations

When invoked with the minimal prompt, the AI MUST:

- Re-read this spec before editing any file
- Touch only the explicitly named file
- Preserve all invariants defined above
- Avoid refactors, cleanups, abstractions, or stylistic rewrites
- Apply the smallest possible patch needed to achieve correctness

Failure to do so constitutes drift and an invalid patch.