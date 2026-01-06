# Supported Items Reference (Phase 1)

This document is a **non-normative reference table** for items supported by the Combine Food mod in **Phase 1**.
It exists to make scope explicit and reviewable without re-reading the full specification.

Authoritative behavior is defined in `mod-spec.md`.  
This table is intended for maintainers, contributors, and future expansion planning.

---

## Legend

- **Eligible (P1)** — Supported in Phase 1
- **Deferred** — Conceptually compatible but intentionally postponed
- **Excluded** — Explicitly out of scope by conceptual boundary

---

## Opened Canned / Jarred Foods (Eligible – Phase 1)

| Display Name | Full Type | Notes |
|-------------|----------|------|
| Canned Beans (Open) | `Base.OpenBeans` | Produces empty tin can |
| Canned Carrots (Open) | `Base.CannedCarrotsOpen` | Produces empty tin can |
| Canned Chili (Open) | `Base.CannedChiliOpen` | Produces empty tin can |
| Canned Corn (Open) | `Base.CannedCornOpen` | Produces empty tin can |
| Canned Corned Beef (Open) | `Base.CannedCornedBeefOpen` | Produces empty tin can |
| Canned Dog Food (Open) | `Base.DogfoodOpen` | Produces empty tin can |
| Canned Evaporated Milk (Open) | `Base.CannedMilkOpen` | Produces empty tin can |
| Canned Fruit Beverage (Open) | `Base.CannedFruitBeverageOpen` | Produces empty tin can |
| Canned Fruit Cocktail (Open) | `Base.CannedFruitCocktailOpen` | Produces empty tin can |
| Canned Mushroom Soup (Open) | `Base.CannedMushroomSoupOpen` | Produces empty tin can |
| Canned Peaches (Open) | `Base.CannedPeachesOpen` | Produces empty tin can |
| Canned Peas (Open) | `Base.CannedPeasOpen` | Produces empty tin can |
| Canned Pineapple (Open) | `Base.CannedPineappleOpen` | Produces empty tin can |
| Canned Potato (Open) | `Base.CannedPotatoOpen` | Produces empty tin can |
| Canned Sardines (Open) | `Base.CannedSardinesOpen` | Produces empty tin can |
| Canned Spaghetti Bolognese (Open) | `Base.CannedBologneseOpen` | Produces empty tin can |
| Canned Tomato (Open) | `Base.CannedTomatoOpen` | Produces empty tin can |
| Canned Tuna (Open) | `Base.TunaTinOpen` | Produces empty tin can |
| Canned Vegetable Soup (Open) | `Base.TinnedSoupOpen` | Produces empty tin can |
| Jar of Bell Peppers (Open) | `Base.CannedBellPepper_Open` | Produces empty jar |
| Jar of Broccoli (Open) | `Base.CannedBroccoli_Open` | Produces empty jar |
| Jar of Cabbage (Open) | `Base.CannedCabbage_Open` | Produces empty jar |
| Jar of Carrots (Open) | `Base.CannedCarrots_Open` | Produces empty jar |
| Jar of Eggplants (Open) | `Base.CannedEggplant_Open` | Produces empty jar |
| Jar of Leeks (Open) | `Base.CannedLeek_Open` | Produces empty jar |
| Jar of Potatoes (Open) | `Base.CannedPotato_Open` | Produces empty jar |
| Jar of Radishes (Open) | `Base.CannedRedRadish_Open` | Produces empty jar |
| Jar of Tomatoes (Open) | `Base.CannedTomato_Open` | Produces empty jar |
| Jar of Fish Roe (Open) | `Base.CannedRoe_Open` | Produces empty jar |
| Marinara | `Base.Marinara` | Produces empty jar |
| Soy Sauce | `Base.Soysauce` | Produces empty jar |

## Sacked Foods (Eligible – Phase 1)

| Flour | `Base.Flour2` | Produces wheat sack |
| Cornmeal | `Base.Cornmeal2` | Produces wheat sack |
| Cornflour | `Base.Cornflour2` | Produces wheat sack |

## Bottled Foods (Eligible – Phase 1)

| Olive Oil | `Base.OilOlive` | Produces empty bottle |
| Vegetable Oil | `Base.OilVegetable` | Produces empty bottle |
| Sesame Oil | `Base.SesameOil` | Produces empty bottle |
| Vinegar | `Base.Vinegar` | Produces empty bottle |
| Rice Vinegar | `Base.RiceVinegar` | Produces empty bottle |

## Squeezy Foods (Eligible – Phase 1)
| Tomato Paste | `Base.TomatoPaste` | Produces aluminum container |

---

## Dried Legumes & Fungible Staples (Eligible – Phase 1)

| Display Name | Full Type | Notes |
|-------------|----------|------|
| Black Beans | `Base.Blackbeans` | Bulk ingredient |
| Dried Black Beans | `Base.DriedBlackBeans` | Bulk ingredient |
| Chick Peas (Dried) | `Base.DriedChickpeas` | Bulk ingredient |
| Kidney Beans (Dried) | `Base.DriedKidneyBeans` | Bulk ingredient |
| Lentils (Dried) | `Base.DriedLentils` | Bulk ingredient |
| Split Peas (Dried) | `Base.DriedSplitPeas` | Bulk ingredient |
| White Beans (Dried) | `Base.DriedWhiteBeans` | Bulk ingredient |
| Soybeans (Dried) | `Base.SoybeansSeed` | Bulk ingredient |
| Soybeans | `Base.Soybeans` | Bulk ingredient |

---

## Processed Bulk Ingredients & Seasonings (Eligible – Phase 1)

This category includes only **processed seasoning items** (e.g., ground, dried-for-use, or packaged seasonings).
Botanical plant items (fresh or dried leaves, flowers, or stems) are excluded even if visually similar.

| Display Name | Full Type | Notes |
|-------------|----------|------|
| Salt | `Base.Salt` | Fungible quantity |
| Seasoning Salt | `Base.SeasoningSalt` | Fungible quantity |
| White Sugar | `Base.Sugar` | Fungible quantity |
| Brown Sugar | `Base.SugarBrown` | Fungible quantity |
| Sugar Packet | `Base.SugarPacket` | Fungible quantity |
| Sugar Cubes | `Base.SugarCubes` | Fungible quantity |
| Honey | `Base.Honey` | Liquid ingredient |
| Maple Syrup | `Base.MapleSyrup` | Liquid ingredient |
| Powdered Garlic | `Base.PowderedGarlic` | Processed seasoning |
| Powdered Onion | `Base.PowderedOnion` | Processed seasoning |
| Pepper | `Base.Pepper` | Processed seasoning |
| Ketchup | `Base.Ketchup` | Processed sauce |
| Mustard | `Base.Mustard` | Processed sauce |
| Barbecue Sauce | `Base.BBQSauce` | Processed sauce |
| Packaged Corn | `Base.CornFrozen` | Frozen bulk ingredient |
| Packaged Peas | `Base.Peas` | Frozen bulk ingredient |
| Mixed Vegetables | `Base.MixedVegetables` | Frozen bulk ingredient |
| Basil (Dried, Seasoning) | `Base.Seasoning_Basil` | Processed seasoning |
| Chives (Dried, Seasoning) | `Base.Seasoning_Chives` | Processed seasoning |
| Cilantro (Dried, Seasoning) | `Base.Seasoning_Cilantro` | Processed seasoning |
| Oregano (Dried, Seasoning) | `Base.Seasoning_Oregano` | Processed seasoning |
| Parsley (Dried, Seasoning) | `Base.Seasoning_Parsley` | Processed seasoning |
| Rosemary (Dried, Seasoning) | `Base.Seasoning_Rosemary` | Processed seasoning |
| Sage (Dried, Seasoning) | `Base.Seasoning_Sage` | Processed seasoning |
| Thyme (Dried, Seasoning) | `Base.Seasoning_Thyme` | Processed seasoning |

---

## Dry Staples, Spreads, and Snack Bags (Eligible – Phase 1)

These items are treated as fungible quantities once opened or partially consumed.
While some are packaged snacks, player expectations already align with consolidation
rather than object identity.

| Display Name | Full Type | Notes |
|-------------|----------|------|
| Oats (Raw) | `Base.OatsRaw` | Bulk dry staple |
| Cereal | `Base.Cereal` | Bulk dry staple |
| Cocoa Powder | `Base.CocoaPowder` | Processed dry ingredient |
| Coffee | `Base.Coffee2` | Bulk dry ingredient |
| Fruit Jam | `Base.JamFruit` | Fungible spread |
| Peanut Butter | `Base.PeanutButter` | Fungible spread |
| Tortilla Chips | `Base.TortillaChips` | Snack bag, quantity‑centric |
| Chips – Plain | `Base.Crisps` | Snack bag, quantity‑centric |
| Chips – Barbecue | `Base.Crisps2` | Snack bag, quantity‑centric |
| Chips – Salt & Vinegar | `Base.Crisps3` | Snack bag, quantity‑centric |
| Chips – Sour Cream & Onion | `Base.Crisps4` | Snack bag, quantity‑centric |
| Dry Cat Food | `Base.CatFoodBag` | Bulk dry feed |
| Dry Dog Food | `Base.DogFoodBag` | Bulk dry feed |

---

## Deferred Candidates (Not Phase 1)

| Display Name | Full Type | Reason |
|-------------|----------|-------|
| Butter | `Base.Butter` | Higher identity / spoilage expectations |
| Margarine | `Base.Margarine` | Same |
| Sour Cream | `Base.SourCream` | Same |
| Lard | `Base.Lard` | Same |
| Pickles | `Base.Pickles` | Pickled-object semantics |
| Ginger (Pickled) | `Base.GingerPickled` | Pickled-object semantics |

---

## Explicitly Excluded (By Conceptual Boundary)

| Category | Examples |
|--------|----------|
| Whole vegetables & fruits | Cabbage, potatoes, apples |
| Botanical herbs & plants | Fresh plants, dried leaves, flowers, stems (non-seasoning items) |
| Seeds & agricultural bundles | Seeds, sheaves, hay, flax, hemp |
| Fried / prepared dishes | Fries, onion rings |
| Flowers & foraged plants | Chamomile, lavender, rose petals |

---

## Notes

- This table is **not executable configuration**.
- Actual eligibility is enforced by the whitelist in `CombineOpenedCans_Util.lua`.
- Changes to this table should be accompanied by spec review.
- Frozen or packaged vegetables are treated as fungible quantities once opened and are eligible for consolidation.
- Items explicitly classified as `Seasoning_*` are treated as processed fungible ingredients; non-seasoning herb items remain excluded.
- Opened jarred foods are treated identically to opened canned foods: contents are fungible quantities and the empty container is preserved as a byproduct.
- Packaged dry foods and snack bags (e.g., cereal, chips, pet food) are considered fungible quantities once opened; consolidation aligns with player expectations.
- Oils and vinegars are treated as containerized liquids and yield a reusable bottle (currently `Base.WineScrewtop`) when emptied.
