def load_containerized_csv(path: Path):
    """
    Reads food-containerized.csv and returns:
      - rows: list of (item_id, [byproducts...])
    """
    rows = []
    with path.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for r in reader:
            item_id = r["item_id"].strip()
            byp = (r.get("byproducts") or "").strip()
            byproducts = [b.strip() for b in byp.split(";") if b.strip()] if byp else []
            rows.append((item_id, byproducts))
    return rows
def emit_containerized_combine_recipe(item_id: str) -> str:
    # item_id like "Base.CannedCornOpen"
    short = item_id.split(".")[-1]
    lines = []
    lines.append(f"    recipe Combine{short}")
    lines.append("    {")
    lines.append(f"        {item_id};2,")
    lines.append(f"        Result : {item_id}=1,")
    lines.append("        Time : 50,")
    lines.append("        Category : Cooking,")
    lines.append("        CanBeDoneFromFloor : true,")
    lines.append("        StopOnWalk        : false,")
    lines.append("        NeedToBeLearn     : false,")
    lines.append("        OnCanPerform : Recipe.OnCanPerform.KitchenConsolidation_Combine_OnCanPerform,")
    lines.append("        OnCreate : Recipe.OnCreate.KitchenConsolidation_Combine_OnCreate,")
    lines.append("    }")
    return "\n".join(lines)
def emit_containerized_lua(rows: list[tuple[str, list[str]]]) -> str:
    lines = []
    lines.append("-- AUTO-GENERATED FILE. DO NOT EDIT.")
    lines.append("RecipeContainerized = RecipeContainerized or {}")
    lines.append("")
    lines.append("local lookup = {")
    for item_id, byps in rows:
        if byps:
            arr = ", ".join([f'\"{b}\"' for b in byps])
            lines.append(f"    [\"{item_id}\"] = {{ {arr} }},")
        else:
            lines.append(f"    [\"{item_id}\"] = {{ }},")
    lines.append("}")
    lines.append("")
    lines.append("function RecipeContainerized.byproductLookup(itemId)")
    lines.append("    return lookup[itemId]")
    lines.append("end")
    return "\n".join(lines)
#!/usr/bin/env python3

import csv
import sys
import re
from pathlib import Path

# NOTE:
# - piece_full_type is derived as "<module>.<piece_name>"
# - display_name_key is derived as "ItemName_<module>.<piece_name>"

USAGE = """
Usage:
  gen-items.py <food-defs.csv> <food-evolved.csv> <mod-root>

Example:
  python gen-items.py food-defs.csv food-evolved-vanilla.csv kitchenconsolidation/media
"""


def die(msg: str):
    print(f"ERROR: {msg}", file=sys.stderr)
    print(USAGE, file=sys.stderr)
    sys.exit(1)


def dash_is_none(value: str):
    if value is None:
        return None
    value = value.strip()
    return None if value == "-" or value == "" else value


def piece_full_type(row: dict) -> str:
    return f"{row['module']}.{row['piece_name']}"


def display_name_key(row: dict) -> str:
    return f"ItemName_{piece_full_type(row)}"


# Helper for evolved item display name key
def evolved_item_display_key(full_type: str, evolved_name: str) -> str:
    # ItemName_KitchenConsolidation.FishPieces_Stew
    return f"ItemName_{full_type}_{evolved_name}"


def humanize_piece_name(piece_name: str) -> str:
    # FishPieces -> Fish Pieces
    out = []
    for i, ch in enumerate(piece_name):
        if i > 0 and ch.isupper() and not piece_name[i - 1].isupper():
            out.append(" ")
        out.append(ch)
    return "".join(out)

# Helper to format evolved item names for pot/pan recipes
def format_pot_pan_evolved_name(base_name: str, evolved_name: str) -> str:
    # evolved_name examples: RicePot, RicePan, PastaPot, PastaPan
    if evolved_name.endswith("Pot"):
        food = evolved_name[:-3]
        return f"Pot of {food} and {base_name}"
    if evolved_name.endswith("Pan"):
        food = evolved_name[:-3]
        return f"Pan of {food} and {base_name}"
    return f"{base_name} {evolved_name}"

# Improved humanize_item_id to normalize underscores
def humanize_item_id(item_id: str) -> str:
    # Base.CannedBellPepper_Open -> Canned Bell Pepper Open
    short = item_id.split(".")[-1].replace("_", " ")
    out = []
    for i, ch in enumerate(short):
        if i > 0 and ch.isupper() and not short[i - 1].isupper() and short[i - 1] != " ":
            out.append(" ")
        out.append(ch)
    return "".join(out)


def recipe_display_name(recipe_prefix: str, piece_name: str) -> str:
    # ("Chop", "FishPieces") -> "Chop Fish Pieces"
    return f"{recipe_prefix} {humanize_piece_name(piece_name)}"


def load_csv_rows(path: Path) -> list[dict]:
    with path.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def load_evolved_matrix(path: Path):
    """
    Reads food-evolved-vanilla.csv and returns:
      - evolved: { recipe_name: [fullType, ...] }
      - keys: set of (module, piece_name)
      - per_item: { (module, piece_name): "Recipe:Value;..." }
    """
    evolved: dict[str, list[str]] = {}
    keys: set[tuple[str, str]] = set()
    per_item: dict[tuple[str, str], str] = {}

    with path.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        if not reader.fieldnames:
            die(f"Evolved CSV has no header: {path}")

        recipe_columns = [c for c in reader.fieldnames if c not in ("module", "piece_name")]

        for row in reader:
            key = (row["module"], row["piece_name"])
            keys.add(key)

            full_type = f"{row['module']}.{row['piece_name']}"
            parts = []

            for recipe in recipe_columns:
                val = (row.get(recipe) or "").strip()
                if val and val != "-":
                    evolved.setdefault(recipe, []).append(full_type)
                    parts.append(f"{recipe}:{val}")

            if parts:
                per_item[key] = ";".join(parts)

    return evolved, keys, per_item


def emit_item(row: dict, evolved_per_item: dict) -> str:
    lines: list[str] = []

    lines.append(f"    item {row['piece_name']}")
    lines.append("    {")
    lines.append(f"        DisplayName        = {display_name_key(row)},")
    lines.append(f"        Icon               = {row['icon']},")
    lines.append(f"        DisplayCategory    = {row['display_category']},")
    lines.append("        Type               = Food,")
    lines.append("")

    # Core consumption
    lines.append("        // Core consumption semantics (fungible pile)")
    lines.append(f"        HungerChange       = {row['hunger_change']},")
    lines.append(f"        BaseHunger         = {row['base_hunger']},")
    lines.append(f"        ThirstChange       = {row['thirst_change']},")
    lines.append("")

    # Nutrition (optional)
    if dash_is_none(row.get('calories', '-')) is not None:
        lines.append("        // Nutrition (base-hunger–scaled; conservative)")
        lines.append(f"        Calories           = {row['calories']},")
        lines.append(f"        Proteins           = {row['proteins']},")
        lines.append(f"        Lipids             = {row['lipids']},")
        lines.append(f"        Carbohydrates      = {row['carbohydrates']},")
        lines.append("")

    # Weight
    lines.append("        // Weight / encumbrance")
    lines.append(f"        Weight             = {row['weight']},")
    lines.append(f"        WeightFull         = {row['weight_full']},")
    lines.append(f"        WeightEmpty        = {row['weight_empty']},")
    lines.append("")

    # Freshness (optional)
    if dash_is_none(row.get('days_fresh', '-')) is not None:
        lines.append("        // Freshness / spoilage")
        lines.append(f"        DaysFresh          = {row['days_fresh']},")
        lines.append(f"        DaysTotallyRotten  = {row['days_totally_rotten']},")
        lines.append("")

    # Mood (optional)
    if dash_is_none(row.get('boredom_change', '-')) is not None:
        lines.append("        // Eating effects")
        lines.append(f"        BoredomChange      = {row['boredom_change']},")
        lines.append(f"        UnhappyChange      = {row['unhappy_change']},")
        lines.append("")

    # Metadata
    lines.append("        // Cooking / ingredient metadata")
    lines.append(f"        FoodType           = {row['food_type']},")
    lines.append(f"        Tags               = {row['tags']},")
    key = (row["module"], row["piece_name"])
    evolved_spec = evolved_per_item.get(key)
    if evolved_spec:
        lines.append(f"        EvolvedRecipe      = {evolved_spec},")
    if (row.get('dangerous_uncooked') or "").strip().lower() == "true":
        lines.append("        DangerousUncooked  = true,")
    lines.append("")
    lines.append("        // General flags")
    lines.append(f"        IsCookable         = {(row.get('is_cookable') or 'true').strip().lower()},")
    lines.append("        CanStoreWater      = false,")
    lines.append("    }")
    return "\n".join(lines)


def emit_chop_recipe(row: dict) -> str:
    if dash_is_none(row.get('chop_input_item_types', '-')) is None:
        return ""

    tools = (row.get('chop_required_tools') or "").replace("|", "/")

    lines: list[str] = []
    lines.append(f"    recipe Chop{row['piece_name']}")
    lines.append("    {")
    lines.append(f"        {row['chop_input_item_types']};1,")
    lines.append(f"        keep {tools},")
    lines.append(f"        Result      : {piece_full_type(row)}=1,")
    lines.append("        Time        : 50,")
    lines.append("        Category    : Cooking,")
    lines.append("        CanBeDoneFromFloor : true,")
    lines.append("        StopOnWalk    		: false,")
    lines.append("        NeedToBeLearn 		: false,")
    lines.append("        OnGiveXP    : Recipe.OnGiveXP.Cooking10,")
    lines.append("        OnCreate    : Recipe.OnCreate.KitchenConsolidation_Chop,")
    lines.append("    }")
    return "\n".join(lines)


def emit_combine_recipe(row: dict) -> str:
    lines: list[str] = []
    lines.append(f"    recipe Combine{row['piece_name']}")
    lines.append("    {")
    lines.append(f"        {piece_full_type(row)};2,")
    lines.append(f"        Result : {piece_full_type(row)}=1,")
    lines.append("        Time : 50,")
    lines.append("        Category : Cooking,")
    lines.append("        CanBeDoneFromFloor : true,")
    lines.append("        StopOnWalk    		: false,")
    lines.append("        NeedToBeLearn 		: false,")
    lines.append("        OnCanPerform : Recipe.OnCanPerform.KitchenConsolidation_Combine_OnCanPerform,")
    lines.append("        OnCreate : Recipe.OnCreate.KitchenConsolidation_Combine_OnCreate,")
    lines.append("    }")
    return "\n".join(lines)


def emit_evolvedrecipes(evolved: dict) -> str:
    lines: list[str] = []
    lines.append("// ------------------------------------------------------------------")
    lines.append("// Kitchen Consolidation – Evolved Recipe Extensions")
    lines.append("// AUTO-GENERATED FILE – DO NOT EDIT BY HAND")
    lines.append("// Source: food-evolved-vanilla.csv")
    lines.append("// ------------------------------------------------------------------")
    lines.append("")    
    lines.append("module Base {")

    for recipe_name in sorted(evolved.keys()):
        lines.append("    // =====================")
        lines.append(f"    // {recipe_name.upper()}")
        lines.append("    // =====================")
        lines.append(f"    evolvedrecipe {recipe_name}")
        lines.append("    {")
        for full_type in sorted(set(evolved[recipe_name])):
            lines.append(f"        Item {full_type},")
        lines.append("    }")
        lines.append("")
    lines.append("}")
    return "\n".join(lines)


def emit_item_translations(rows: list[dict], evolved_per_item: dict) -> str:
    lines = []
    lines.append("# --------------------------------------------------")
    lines.append("# Kitchen Consolidation – Item Names (EN)")
    lines.append("# AUTO-GENERATED FILE – DO NOT EDIT BY HAND")
    lines.append("# --------------------------------------------------")
    lines.append("")
    lines.append("ItemName_EN = {")

    for row in rows:
        base_name = humanize_piece_name(row["piece_name"])
        key = display_name_key(row)
        # IMPORTANT: emit as string key
        lines.append(f"    [\"{key}\"] = \"{base_name}\",")

    lines.append("}")
    return "\n".join(lines)


def emit_recipe_translations(rows: list[dict], containerized_rows: list[tuple[str, list[str]]]) -> str:
    lines = []
    seen = set()

    lines.append("# --------------------------------------------------")
    lines.append("# Kitchen Consolidation – Recipe Names (EN)")
    lines.append("# AUTO-GENERATED FILE – DO NOT EDIT BY HAND")
    lines.append("# --------------------------------------------------")
    lines.append("")
    lines.append("Recipes_EN = {")

    # Pieces recipes
    for row in rows:
        piece = row["piece_name"]

        if dash_is_none(row.get("chop_input_item_types", "-")) is not None:
            key = f"Recipe_Chop{piece}"
            if key not in seen:
                display = recipe_display_name('Chop', piece)
                display = re.sub(r"\s*\d+$", "", display)
                lines.append(f"    [\"{key}\"] = \"{display}\",")
                seen.add(key)

        key = f"Recipe_Combine{piece}"
        if key not in seen:
            display = recipe_display_name('Combine', piece)
            display = re.sub(r"\s*\d+$", "", display)
            lines.append(f"    [\"{key}\"] = \"{display}\",")
            seen.add(key)

    # Containerized combine recipes
    for item_id, _ in sorted(containerized_rows, key=lambda x: x[0]):
        short = item_id.split(".")[-1]
        key = f"Recipe_Combine{short}"
        if key not in seen:
            value = f"Combine {humanize_item_id(item_id)}"
            # Trim trailing " Open"
            if value.endswith(" Open"):
                value = value[:-5]
            # Trim trailing digits (e.g. "Crisps2" -> "Crisps")
            value = re.sub(r"\s*\d+$", "", value)
            lines.append(f"    [\"{key}\"] = \"{value}\",")
            seen.add(key)

    lines.append("}")
    return "\n".join(lines)


def main():
    containerized_csv = Path("food-containerized.csv")
    if not containerized_csv.exists():
        die(f"food-containerized.csv not found: {containerized_csv}")

    containerized_rows = load_containerized_csv(containerized_csv)
    if len(sys.argv) != 4:
        die("Expected 3 arguments")

    defs_path = Path(sys.argv[1])
    evolved_path = Path(sys.argv[2])
    mod_root = Path(sys.argv[3])

    if not defs_path.exists():
        die(f"food-defs.csv not found: {defs_path}")
    if not evolved_path.exists():
        die(f"food-evolved CSV not found: {evolved_path}")

    scripts_folder = mod_root / "scripts"
    scripts_folder.mkdir(parents=True, exist_ok=True)

    translate_en = mod_root / "lua" / "shared" / "Translate" / "EN"
    translate_en.mkdir(parents=True, exist_ok=True)

    # Deterministic ordering
    rows = sorted(load_csv_rows(defs_path), key=lambda r: r["piece_name"])
    containerized_rows = sorted(containerized_rows, key=lambda x: x[0])
    evolved, evolved_keys, evolved_per_item = load_evolved_matrix(evolved_path)

    # Validate 1:1 correspondence
    item_keys = {(r["module"], r["piece_name"]) for r in rows}
    if item_keys != evolved_keys:
        missing = item_keys - evolved_keys
        extra = evolved_keys - item_keys
        if missing:
            die(f"Items missing from evolved CSV: {sorted(missing)}")
        if extra:
            die(f"Extra items in evolved CSV: {sorted(extra)}")

    # Generate consolidated pieces.txt file
    pieces_lines: list[str] = []
    pieces_lines.append("module KitchenConsolidation")
    pieces_lines.append("{")
    pieces_lines.append("    imports")
    pieces_lines.append("    {")
    pieces_lines.append("        Base,")
    pieces_lines.append("    }")
    pieces_lines.append("")
    for row in rows:
        # ---- item definition ----
        pieces_lines.append(emit_item(row, evolved_per_item))
        pieces_lines.append("")

        # ---- chop recipe (optional) ----
        chop = emit_chop_recipe(row)
        if chop:
            pieces_lines.append(chop)
            pieces_lines.append("")

        # ---- combine recipe ----
        pieces_lines.append(emit_combine_recipe(row))
        pieces_lines.append("")
    pieces_lines.append("}")

    pieces_path = scripts_folder / "pieces.txt"
    pieces_path.write_text("\n".join(pieces_lines), encoding="utf-8")
    print(f"Wrote {pieces_path}")

    # Generate containerized.txt
    cont_lines: list[str] = []
    cont_lines.append("module KitchenConsolidation")
    cont_lines.append("{")
    cont_lines.append("    imports")
    cont_lines.append("    {")
    cont_lines.append("        Base,")
    cont_lines.append("    }")
    cont_lines.append("")

    for item_id, _ in sorted(containerized_rows, key=lambda x: x[0].lower()):
        cont_lines.append(emit_containerized_combine_recipe(item_id))
        cont_lines.append("")

    cont_lines.append("}")

    cont_path = scripts_folder / "containerized.txt"
    cont_path.write_text("\n".join(cont_lines), encoding="utf-8")
    print(f"Wrote {cont_path}")

    # # Generate evolvedrecipes.txt
    # evolved_out = scripts_folder / "evolvedrecipes.txt"
    # evolved_out.write_text(emit_evolvedrecipes(evolved), encoding="utf-8")
    # print(f"Wrote {evolved_out}")

    # Generate English translations
    item_names_path = translate_en / "ItemName_EN.txt"
    recipe_names_path = translate_en / "Recipes_EN.txt"

    item_names_path.write_text(
        emit_item_translations(rows, evolved_per_item),
        encoding="utf-8"
    )
    recipe_names_path.write_text(
        emit_recipe_translations(rows, containerized_rows),
        encoding="utf-8"
    )

    print(f"Wrote {item_names_path}")
    print(f"Wrote {recipe_names_path}")

    # Generate RecipeContainerized.lua
    lua_path = mod_root / "lua" / "server" / "RecipeContainerized.lua"
    lua_path.parent.mkdir(parents=True, exist_ok=True)
    lua_path.write_text(
        emit_containerized_lua(containerized_rows),
        encoding="utf-8"
    )
    print(f"Wrote {lua_path}")


if __name__ == "__main__":
    main()
