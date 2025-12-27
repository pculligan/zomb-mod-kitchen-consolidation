# Architecture

This document describes the internal structure of **Kitchen Consolidation**,
including file layout, responsibilities, and how data flows through the system.
It is intended for maintainers and contributors rather than end users.

The architecture is intentionally simple and explicit, favoring clarity over
cleverness.

---

## High-Level Structure

Kitchen Consolidation is organized into four conceptual layers:

1. **Item Definitions**  
2. **Utility Layer**  
3. **Action Layer**  
4. **UI Integration Layer**

Each layer has a narrow responsibility and minimal coupling to the others.

---

## Item Definitions

**Location:**
```
media/scripts/
```

Item definition files declare new `Food` items such as prepared “Pieces”.

Responsibilities:
- Define item type (`Food`)
- Define base hunger for full items
- Define visuals, weight, and metadata
- Do *not* encode consolidation logic

Examples:
- `fish.txt`
- `meat.txt`
- `vegetables.txt`

Item scripts are treated as *static descriptors*, not sources of runtime truth.

---

## Utility Layer

**Location:**
```
media/lua/shared/KitchenConsolidation_Util.lua
```

Responsibilities:
- Centralize all hunger access (`getHungChange` / `setHungChange`)
- Implement authoritative fraction math
- Provide strict eligibility checks
- Emit diagnostic logging

The utility layer owns:
- `KC_FullHunger` interpretation
- Fraction calculation
- Safety checks and refusal semantics

No UI or inventory mutation logic lives here.

---

## Action Layer

**Location:**
```
media/lua/shared/
```

Primary actions:
- `PrepareAction.lua`
- `ConsolidateAction.lua`

Responsibilities:
- Mutate inventory state
- Create and destroy items
- Assign `KC_FullHunger`
- Preserve vanilla state

### PrepareAction

- Converts source items into prepared “Pieces”
- Computes canonical maximum hunger as the sum of source hunger
- Stores `KC_FullHunger` on prepared items
- Preserves all vanilla state (freshness, poison, cooked state)

### ConsolidateAction

- Merges partial prepared items
- Preserves total hunger exactly
- Emits byproducts when appropriate
- Refuses unsafe or ambiguous operations

Actions are executed exclusively via timed actions to ensure
multiplayer safety.

---

## Defensive Layering and Validation Strategy

Kitchen Consolidation intentionally applies *redundant validation* across layers.
This is a design decision driven by multiplayer safety, engine behavior, and
hard‑won debugging experience.

The same invariants may be checked more than once, but **for different reasons**.

### Validation Layer (UI / isValid)

The UI and `isValid` checks exist to:
- Prevent invalid or ambiguous actions from being offered
- Reduce user confusion
- Avoid unnecessary timed actions

These checks are *advisory*, not authoritative.

### Execution Layer (Action.perform)

The `perform()` method is authoritative and must:
- Re‑validate all eligibility constraints
- Assume UI‑side checks may be stale, skipped, or desynced
- Fail closed rather than guessing

This layer protects against:
- Multiplayer desync
- Inventory changes during action execution
- Engine reordering or partial updates

### Utility Layer (Shared Truth)

The utility layer defines the **single source of truth** for:
- Hunger math
- Freshness bucket classification
- Eligibility predicates
- Invariant enforcement

Both UI and action layers delegate to these helpers to avoid divergence.

### Why Redundancy Is Intentional

Redundant validation is not accidental duplication.

It exists because:
- UI logic can be bypassed or invalidated
- Timed actions may execute later under different conditions
- Multiplayer replication is not instantaneous
- The engine does not guarantee atomic inventory state

Any attempt to “optimize away” these checks risks correctness bugs.

> **If an invariant matters, it must be enforced at execution time — even if it was already checked earlier.**

---

## UI Integration Layer

**Location:**
```
media/lua/client/
```

Primary files:
- `Prepare.lua`
- `Consolidate.lua`

Responsibilities:
- Hook into inventory context menus
- Detect eligible items
- Present explicit user options
- Dispatch actions

The UI layer does not contain business logic. All decisions are delegated
to the utility and action layers.

---

## Data Flow Overview

1. **UI Layer**
   - Detects candidate items
   - Offers context menu options

2. **Action Layer**
   - Validates intent
   - Executes inventory mutations

3. **Utility Layer**
   - Performs hunger math
   - Enforces eligibility invariants

4. **Engine**
   - Applies consumption semantics
   - Updates hunger during eating/cooking

Data ownership is unidirectional and explicit.

---

## Multiplayer Considerations

- All inventory mutations occur inside timed actions
- No client-only state affects hunger math
- `modData` values are replicated and authoritative
- No background or automatic processing occurs

This ensures deterministic behavior in multiplayer environments.

---

## Logging and Diagnostics

Kitchen Consolidation includes verbose diagnostic logging to make engine
behavior observable.

Logging is centralized in the utility layer and focuses on:
- Hunger reads and writes
- Eligibility decisions
- Refusal reasons
- Invariant violations

This logging is intended for development and debugging, not end users.

---

## Design Principles

The architecture follows these principles:

- **Explicit ownership** over implicit inference
- **Fail closed** rather than guessing
- **Minimal engine interference**
- **Clear separation of concerns**

These principles are non-negotiable.

---

## Extension Points

Future extensions may add:

- New preparation mappings
- Additional fungible item categories
- Alternative UI presentations

Extensions must preserve:
- Hunger ownership rules
- Consolidation invariants
- Multiplayer safety guarantees

---

## Architectural Invariant

> **No layer infers or corrects the responsibilities of another layer.**

Violations of this invariant should be treated as design defects.

## Dev Setup
```
rm -rf .venv
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install openai
```