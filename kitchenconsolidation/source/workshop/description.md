# Kitchen Consolidation

Fixes food fragmentation without breaking balance or immersion.

- Safely combines leftover food
- Lets you prepare small meat and fish pieces into usable piles
- Works with stews and soups without changing vanilla balance
- No free food, no buffs, no recipe overrides

## What problem does this mod solve?

In Project Zomboid, food management often breaks down — not because food is scarce, but because it becomes **fragmented**.

You end up with plenty of food that’s technically edible, but practically useless:

- Partially‑used cans cluttering your inventory  
- Many small or partial cuts that can’t be combined  
- Leftovers that don’t justify taking up a stew or soup slot  
- Cooking systems that punish variety instead of preparation  

The result is busywork, not survival gameplay.

**Kitchen Consolidation fixes that.**

### Important clarification

Many foods already support **partial use** — ground beef, butter, lard, and similar items work fine in vanilla.

Kitchen Consolidation doesn’t replace that behavior.

It fixes **fragmentation under constraint**:
- Too many incompatible leftovers
- Too few ingredient slots
- Perfectly usable food becoming impractical to cook/add

## What this mod does

### 🥫 Consolidate opened / partial foods
- Combine opened cans and jars of the same food
- Items must share the **same freshness state**
- Empty containers are returned (cans, jars, lids)
- Nutrition, freshness, and sickness are preserved conservatively
- Consolidation always preserves worst-case freshness and never improves food quality

**Result:** fewer half‑cans cluttering your inventory.


### 🐟 Prepare fish into Fish Pieces
- Fish fillets are **explicitly prepared**
- Produces **Fish Pieces**, a fungible pile
- Fish Pieces:
  - behave like ground meat
  - can be partially used
  - integrate cleanly into stews and soups
- Raw fish remains dangerous until cooked

**Result:** small fish and partial fillets stay useful.


### 🥩 Prepare meat into Meat Pieces
- Raw meats can be prepared into **Meat Pieces**
- Works for:
  - vanilla meats
  - modded meats
  - containerized meats (e.g. canned ham)
- Containerized meats correctly return empty containers
- Meat Pieces:
  - are additive piles
  - scale by hunger (portion‑based)
  - work with stews and soups
  - preserve sickness and poison behavior

**Result:** meat preparation finally works like a real kitchen.

### 🍖 Realistic pile sizes for Pieces
- Pieces now represent larger, realistic piles rather than tiny fragments
- Weight and nutrition scale accordingly to reflect meaningful portions

**Result:** prepared piles feel substantial and practical.

### ⚙️ Optional auto-consolidation
- Auto-consolidation exists but is enabled by default (`SandboxVars.KitchenConsolidation.AutoConsolidate == true`)
- Only triggers after explicit preparation
- No background or player-tick consolidation occurs

**Result:** preparation remains explicit and player-controlled.

## What this mod does **not** do

- ❌ No free food  
- ❌ No nutrition buffs  
- ❌ No recipe overrides  
- ❌ No cooking shortcuts  
- ❌ No “merge raw steaks into super‑steak”  
- ❌ No early warnings about poison or sickness  

If something is unsafe, it stays unsafe.  
If something spoils, it still spoils.


## Design philosophy

Kitchen Consolidation follows three rules:

1. **Preparation is explicit**  
   Nothing is merged automatically.

2. **Worst‑case safety applies**  
   Mixing food never makes it safer.

3. **Vanilla systems come first**  
   Stews, soups, nutrition, and spoilage all use base‑game mechanics.

This mod fixes friction — not difficulty.


## Compatibility

Kitchen Consolidation is designed to be **compatibility‑first**.  
It avoids recipe overrides, global hooks, and invasive patches so it can coexist cleanly with other mods.

### Actively supports (but does not require)
- [Soul Filcher's Cooking Time](https://steamcommunity.com/sharedfiles/filedetails/?id=1910606509)
- [Food Preservation Plus](https://steamcommunity.com/sharedfiles/filedetails/?id=2890748284)

### Transparent to
- [AnaLGiNs Renewable Food Resources](https://steamcommunity.com/sharedfiles/filedetails/?id=2688622178)
- [Can Soup and Stew](https://steamcommunity.com/sharedfiles/filedetails/?id=3352647720)
- [CZ Cooking](https://steamcommunity.com/sharedfiles/filedetails/?id=3387549572)
- [Herbalist](https://steamcommunity.com/sharedfiles/filedetails/?id=2875059598)
- [Hotdogs & Lard / Pickled Meats Addon](https://steamcommunity.com/sharedfiles/filedetails/?id=3371887045) *(active support coming)*
- [More Jerky](https://steamcommunity.com/sharedfiles/filedetails/?id=3265709024) *(active support coming)*
- [Sapph's Cooking](https://steamcommunity.com/sharedfiles/filedetails/?id=2832136889) *(awesome mod! let me know if there is a desire to support something here)*
- [WhopperMod](https://steamcommunity.com/sharedfiles/filedetails/?id=3515027500)

Load this mod **after** the mods it actively supports.

### How compatibility works
- **Vanilla‑first behavior**  
  All consolidation and preparation logic builds on existing base‑game mechanics (hunger, freshness, evolved recipes).
- **Whitelist‑driven integration**  
  Eligible items are defined via centralized source lists.
- **Container behavior preserved**  
  Containerized foods correctly return empty containers.

### Multiplayer and saves
- Multiplayer‑safe (no server‑only logic or client‑only hacks)
- Existing saves supported  
  *(new item scripts require new item spawns, as with vanilla)*


## Supported languages

- English
- čeština (Czech)
- Deutsch (German)
- español (Spanish)
- français (French)
- italiano (Italian)
- 日本語 (Japanese)
- 한국어 (Korean)
- polski (Polish)
- português (Portuguese)
- português do Brasil (Brazilian Portuguese)
- русский (Russian)
- ไทย (Thai)
- Türkçe (Turkish)
- українська (Ukrainian)
- 中文（简体） (Simplified Chinese)
- 中文（繁體） (Traditional Chinese)

English is the source language. Other languages may initially ship with provisional translations and improve over time.


## Contributing translations

Translations are generated from English templates and organized by language files.

**Guidelines:**
- Translate values only — never keys
- Preserve placeholders exactly (e.g. `%1`)
- Keep translations concise and suitable for in‑game UI

To help improve translations:
- Open an issue on the Workshop page, or
- Submit a [pull request](https://github.com/pculligan/zomb-mod-kitchen-consolidation)


## Planned expansion (not promises)

Future phases may explore:
- additional mod compatibility
- further reductions in food inventory busywork
- more translations (by request)

Only if they fit the same philosophy.


## In case of issues after updates

1. Quit the game
2. Restart Project Zomboid
3. Start a **new save** for new item scripts

Item definitions are cached by the B41 engine. I won't code this for B42 until multiplayer comes out and stabilizes a little.

Submit bugs on [Github](https://github.com/pculligan/zomb-mod-kitchen-consolidation).


## Ask for permission

This mod can only be added to and extended with the express permission from the original creator.  
If no permission is received you may not alter the mod, and it must be treated as a mod that is **On Lockdown**.  
You are not allowed to repack this mod under any circumstances.

[Official disclaimer…](https://theindiestone.com/forums/index.php?/topic/2530-mod-permissions/#comment-36478)

Contributions are very welcome, particularly around additional mod compatibility.  
Please submit PRs on [Github](https://github.com/pculligan/zomb-mod-kitchen-consolidation).

All rights reserved.


Workshop ID: 3625854407
Mod ID: kitchenconsolidation