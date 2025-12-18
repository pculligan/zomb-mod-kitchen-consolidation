# zomb-mod-kitchen-consolidation
Project Zomboid mod for consolidating partial cooking portions where it makes sense. 

# Kitchen Consolidation

**Project Zomboid (Build 41) mod** that reduces food fragmentation by allowing
reasonable consolidation and preparation of partial cooking portions —
without changing vanilla balance, safety rules, or cooking mechanics.

This repository is intentionally documented in depth.  
Kitchen Consolidation is less about *features* and more about *doing the right thing
the right way* inside the Project Zomboid engine.


## What this mod does (high level)

Kitchen Consolidation addresses a mid‑/late‑game problem in Project Zomboid:
**food fragmentation under constraint**.

The mod introduces:
- Conservative consolidation of opened container foods
- Explicit preparation steps that convert many small food items into
  **fungible piles** that behave like vanilla partial‑use foods
- Clean integration with stews and soups using **EvolvedRecipe**
- Strict preservation of vanilla rules around freshness, sickness, and poisoning

It does **not** add free food, buffs, shortcuts, or recipe overrides.

For the full player‑facing explanation, see:
- 📄 **Workshop description**: [`workshop-text.md`](./workshop-text.md)


## Design philosophy (summary)

Kitchen Consolidation follows three core rules:

1. **Preparation is explicit**  
   Nothing is merged automatically. Identity is discarded only by player action.

2. **Worst‑case safety applies**  
   Mixing food never makes it safer than its worst ingredient.

3. **Vanilla systems come first**  
   Hunger, freshness, spoilage, poisoning, stews, and soups all use base‑game mechanics.

These rules are enforced both in code and in the spec.


## Repository structure

```
.
├── README.md                      # This file
├── mod-spec.md                    # Canonical design & behavior specification
├── learnings.md                   # Engine quirks and hard‑won lessons
├── workshop-text.md               # Steam Workshop description
│
├── media/
│   ├── scripts/                   # Item definitions (PZ DSL, not Lua)
│   │   ├── kitchenconsolidation_fishpieces.txt
│   │   └── kitchenconsolidation_meatpieces.txt
│   │
│   └── lua/
│       ├── client/                # Context menus (UI only)
│       │   ├── KitchenConsolidation_Context.lua
│       │   ├── KitchenConsolidation_PrepareFish.lua
│       │   └── KitchenConsolidation_PrepareMeat.lua
│       │
│       └── shared/                # Core logic and policies
│           ├── KitchenConsolidation_Util.lua
│           ├── KitchenConsolidation_PrepareFishAction.lua
│           ├── KitchenConsolidation_PrepareMeatAction.lua
│           ├── KitchenConsolidation_Meats.lua
│           └── Translate/
│               └── EN/
│                   ├── ContextMenu_EN.txt
│                   └── ItemName_EN.txt
│
└── scripts/
    ├── dev-symlink.sh             # Dev helper: symlink mod into Zomboid/mods
    └── translate.py               # Translation generator using OpenAI
```


## Specification and behavior reference

The **canonical source of truth** for behavior is:

- 📐 [`mod-spec.md`](./mod-spec.md)

It defines:
- Phase 1: container consolidation
- Phase 2: fish preparation
- Phase 3: meat preparation
- Guarantees, non‑goals, and safety rules

If behavior and code ever diverge, the spec should be updated first.


## Script architecture (important)

### Client scripts (`media/lua/client`)
- Responsible only for:
  - context menu visibility
  - item selection
  - launching timed actions
- Must not mutate inventory directly
- Must not encode policy

### Shared scripts (`media/lua/shared`)
- Contain all **gameplay logic**
- Timed actions mutate inventory
- Policies (whitelists, byproducts) are centralized here
- No UI assumptions

### Item scripts (`media/scripts`)
- Use the Project Zomboid **item DSL**, not Lua
- Extremely fragile: syntax errors fail silently
- Changes usually require a **new save** to take effect


## Whitelists and policy files

Eligibility is always data‑driven.

Examples:
- `KitchenConsolidation_Meats.lua`
  - `Meats.SOURCES` → which raw meats can be prepared
  - `Meats.BYPRODUCT_ON_EMPTY` → containerized meats (e.g. canned ham → empty can)

Actions consume these policies; they do not define them.

This makes compatibility and extension safe and predictable.


## Development workflow

### Symlink for fast iteration (recommended)

Instead of copying the mod on every change, symlink it:

```bash
./scripts/dev-symlink.sh add kitchenconsolidation ~/dev ~/Zomboid/mods
```

Remove later with:

```bash
./scripts/dev-symlink.sh remove ~/Zomboid/mods/kitchenconsolidation
```

### Testing notes

- Lua changes → reload world or restart game
- Item script changes → **restart game + new save**
- Icons and EvolvedRecipe changes are cached aggressively


## Localization & translations

English is the source language.

Translations live in:
```
media/lua/shared/Translate/<LANG>/
```

Supported / planned languages are listed in the Workshop description.

### Translation generation

This repo includes a helper script that:
- Uses the EN files as a template
- Calls OpenAI with a **context‑rich prompt**
- Preserves keys, placeholders, and formatting

See:
```bash
python3 scripts/translate.py --help
```

Guidelines:
- Translate values only, never keys
- Preserve placeholders like `%1`
- Keep strings short and UI‑appropriate


## Engine learnings (read this)

If you plan to extend this mod or write your own:
- 📘 [`learnings.md`](./learnings.md)

This document captures:
- PZ item DSL pitfalls
- EvolvedRecipe quirks
- Float behavior
- Context menu duplication
- Save invalidation rules
- Why some “obvious” approaches fail

It exists to prevent regressions and wasted time.


## Contributions

Contributions are welcome, especially:
- additional mod compatibility
- translation improvements
- bug fixes with reproduction steps

Please:
- open an issue to discuss behavior changes
- keep changes aligned with the spec
- avoid recipe overrides or invasive hooks

See the Workshop page for permission and redistribution rules.


## License / permissions

This mod may not be repackaged or redistributed without explicit permission
from the author.

See:
- Official Indie Stone mod permissions:
  https://theindiestone.com/forums/index.php?/topic/2530-mod-permissions/#comment-36478

All rights reserved.