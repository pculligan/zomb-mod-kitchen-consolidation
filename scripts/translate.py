#!/usr/bin/env python3
"""
translate.py

Generate Project Zomboid Build 41 localization files by translating the EN tables
with OpenAI, using a context-rich prompt.

Inputs (expected):
  media//Translate/EN/ItemName_EN.txt
  media//Translate/EN/Recipes_EN.txt

Outputs (generated per language, unless already exists):
  media//Translate/<LANG>/ItemName_<LANG>.txt
  media//Translate/<LANG>/Recipes_<LANG>.txt

Notes:
- Build 41 uses domain-specific tables (ItemName_XX, Recipes_XX).
- Keys MUST remain identical. Only the *values* are translated.
- Preserve placeholders like %1 exactly.
- Preserve punctuation, parentheses, and Lua table structure
- Does not overwrite existing files unless --force



"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple, Optional

# OpenAI SDK (Responses API)
# Install: pip install openai
try:
    from openai import OpenAI
except Exception as e:  # pragma: no cover
    OpenAI = None  # type: ignore


LANGS_DEFAULT = [
    "CS",   # čeština
    "DE",   # Deutsch
    "ES",   # español
    "FR",   # français
    "IT",   # italiano
    "JA",   # 日本語
    "KO",   # 한국어
    "PL",   # polski
    "PT",   # português
    "PTBR", # português do Brasil
    "RU",   # русский
    "TH",   # ไทย
    "TR",   # Türkçe
    "UK",   # українська
    "UA",   # українська (alternate code)
    "NL",   # Nederlands
    "ZH",   # 中文（简体）
    "ZHTW", # 中文（繁體）
    "CN",   # Chinese (generic)
    "CH",   # Chinese (alternate)
]

DOMAIN_FILES = [
    ("ItemName", "ItemName"),
    ("Recipes", "Recipes"),
]


@dataclass(frozen=True)
class DomainTable:
    domain: str              # e.g. "ContextMenu"
    table_name: str          # e.g. "ContextMenu_EN"
    entries: Dict[str, str]  # key -> value


TABLE_HEADER_RE = re.compile(r"^\s*([A-Za-z0-9_]+)\s*=\s*\{\s*$")
ENTRY_RE = re.compile(
    r'''
    ^\s*
    (?:                             # either:
        \[\s*"([^"]+)"\s*\]         #   ["string.key"]
      |                             # or
        ([A-Za-z0-9_.]+)            #   bare_identifier
    )
    \s*=\s*
    "(.*)"
    \s*,?\s*$
    ''',
    re.VERBOSE,
)
TABLE_END_RE = re.compile(r"^\s*\}\s*$")


def read_domain_table(path: Path) -> DomainTable:
    """
    Parse a PZ translation file like:
      ContextMenu_EN = {
        ContextMenu_Foo = "Bar",
      }
    Returns domain + entries (keys/values).
    """
    if not path.exists():
        raise FileNotFoundError(f"Missing translation template: {path}")

    table_name: Optional[str] = None
    entries: Dict[str, str] = {}
    in_table = False

    for line in path.read_text(encoding="utf-8").splitlines():
        if not in_table:
            m = TABLE_HEADER_RE.match(line)
            if m:
                table_name = m.group(1)
                in_table = True
            continue

        # inside table
        if TABLE_END_RE.match(line):
            in_table = False
            break

        m = ENTRY_RE.match(line)
        if m:
            key = m.group(1) or m.group(2)
            val = m.group(3)
            # Unescape any escaped quotes in the value
            val = val.replace('\\"', '"')
            entries[key] = val

    if not table_name:
        raise ValueError(f"Could not find table header in {path}")
    domain = table_name.split("_", 1)[0]
    if domain == "Recipe":
        raise ValueError(
            f"Invalid singular Recipe table detected in {path}. "
            f"Expected 'Recipes_EN', not 'Recipe_EN'."
        )
    return DomainTable(domain=domain, table_name=table_name, entries=entries)


def validate_existing_target(
    src: DomainTable,
    existing_path: Path,
    lang: str,
) -> None:
    """
    Ensure an existing target translation file has:
    - no extra keys
    - no missing keys
    compared to the EN source.
    """
    existing = read_domain_table(existing_path)

    src_keys = set(src.entries.keys())
    existing_keys = set(existing.entries.keys())

    extra = sorted(existing_keys - src_keys)
    missing = sorted(src_keys - existing_keys)

    if extra or missing:
        msg = [f"[{lang}] Translation drift detected in {existing_path}:"]
        if extra:
            msg.append(f"  Extra keys ({len(extra)}): {extra[:10]}{'...' if len(extra) > 10 else ''}")
        if missing:
            msg.append(f"  Missing keys ({len(missing)}): {missing[:10]}{'...' if len(missing) > 10 else ''}")
        raise ValueError("\n".join(msg))


def write_domain_table(out_path: Path, domain: str, lang: str, entries: Dict[str, str]) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)

    table_name = f"{domain}_{lang}"
    lines: List[str] = []
    lines.append(f"{table_name} = {{")
    # Stable ordering (by key) for diff friendliness
    for key in sorted(entries.keys()):
        val = entries[key]
        # Escape quotes for Lua table string literal
        val = val.replace('"', '\\"')
        lines.append(f'    ["{key}"] = "{val}",')
    lines.append("}")
    lines.append("")  # newline

    out_path.write_text("\n".join(lines), encoding="utf-8")


def build_translation_prompt(
    domain: str,
    lang: str,
    entries: Dict[str, str],
    mod_name: str = "Kitchen Consolidation",
) -> str:
    """
    Context-rich prompt so translations are accurate and consistent with usage.
    """
    # Keep prompt compact but explicit. Include hard rules.
    context = f"""
You are translating UI strings for a Project Zomboid Build 41 mod named "{mod_name}".

These strings appear in:
- right-click context menus (ContextMenu_* keys), or
- item names in inventory/tooltips (ItemName_* keys).

Rules:
1) DO NOT translate keys. Only translate the English values.
2) Preserve placeholders EXACTLY (e.g. "%1"). Do not remove, reorder, or add new placeholders.
3) Keep punctuation and parentheses unless the target language requires minor changes.
4) Keep the tone practical and short; these are in-game UI labels.
5) Do NOT add new keys. Output must include every key provided.
6) Output JSON ONLY: a single object mapping each key to its translated string.
7) If a value is a proper noun (e.g. "Kitchen Consolidation"), keep it in English unless a commonly accepted localized form exists.
8) If the best translation is unclear, prefer a literal, safe translation over creative paraphrase.
""".strip()

    payload = {
        "domain": domain,
        "target_language": lang,
        "entries": entries,
    }
    return context + "\n\n" + "DATA:\n" + json.dumps(payload, ensure_ascii=False)


def call_openai_translate(
    client: "OpenAI",
    model: str,
    prompt: str,
    timeout_s: int = 120,
) -> Dict[str, str]:
    """
    Calls OpenAI Responses API and expects strict JSON output mapping keys->translated strings.
    """
    resp = client.responses.create(
        model=model,
        input=[
            {"role": "developer", "content": "You are a careful localization engine. Follow all rules and output JSON only."},
            {"role": "user", "content": prompt},
        ],
    )

    text = getattr(resp, "output_text", None)
    if not text:
        # Fallback: some SDK versions expose output differently
        text = str(resp)

    # Strip code fences if the model adds them
    text = text.strip()
    text = re.sub(r"^```(?:json)?\s*", "", text)
    text = re.sub(r"\s*```$", "", text)

    try:
        data = json.loads(text)
    except json.JSONDecodeError as e:
        raise ValueError(f"Model did not return valid JSON. First 400 chars:\n{text[:400]}") from e

    if not isinstance(data, dict):
        raise ValueError("Model JSON was not an object/dict.")

    # Ensure all values are strings
    out: Dict[str, str] = {}
    for k, v in data.items():
        if not isinstance(k, str) or not isinstance(v, str):
            raise ValueError("Model JSON must map string keys to string values.")
        out[k] = v

    return out


def validate_translation(
    src_entries: Dict[str, str],
    translated: Dict[str, str],
    lang: str,
) -> Dict[str, str]:
    """
    Ensure keys match and placeholders are preserved.
    """
    src_keys = set(src_entries.keys())
    out_keys = set(translated.keys())

    missing = sorted(src_keys - out_keys)
    extra = sorted(out_keys - src_keys)

    if missing:
        raise ValueError(f"[{lang}] Missing keys in translation: {missing[:10]}{'...' if len(missing) > 10 else ''}")
    if extra:
        raise ValueError(f"[{lang}] Extra keys in translation: {extra[:10]}{'...' if len(extra) > 10 else ''}")

    # Placeholder preservation: ensure all %<digit> tokens in src appear in translated
    placeholder_re = re.compile(r"%\d")
    for k, src_val in src_entries.items():
        src_ph = placeholder_re.findall(src_val)
        out_ph = placeholder_re.findall(translated[k])
        if sorted(src_ph) != sorted(out_ph):
            raise ValueError(
                f"[{lang}] Placeholder mismatch for key {k}: "
                f"src={src_ph} out={out_ph} (src='{src_val}' out='{translated[k]}')"
            )

    return translated


def main() -> int:
    ap = argparse.ArgumentParser(description="Generate PZ B41 translations via OpenAI using EN as template.")
    ap.add_argument("--base-dir", default="kitchenconsolidation/media/lua//Translate", help="Translate directory (default: kitchenconsolidation/media/lua//Translate)")
    ap.add_argument("--model", default="gpt-5.2", help="OpenAI model name (default: gpt-5.2)")
    ap.add_argument("--langs", nargs="*", default=LANGS_DEFAULT, help="Target language codes (default: common set)")
    ap.add_argument("--force", action="store_true", help="Overwrite existing target files")
    ap.add_argument("--dry-run", action="store_true", help="Do not write files; just show what would be done")
    ap.add_argument("--sleep", type=float, default=0.5, help="Seconds to sleep between API calls (default: 0.5)")
    args = ap.parse_args()

    if OpenAI is None:
        print("ERROR: openai SDK not installed. Run: pip install openai", file=sys.stderr)
        return 2

    base_dir = Path(args.base_dir)
    en_dir = base_dir / "EN"
    if not en_dir.exists():
        print(f"ERROR: EN translation folder not found: {en_dir}", file=sys.stderr)
        return 2

    client = OpenAI()

    # Load EN templates
    templates: List[Tuple[str, Path, DomainTable]] = []
    for domain, prefix in DOMAIN_FILES:
        src_path = en_dir / f"{prefix}_EN.txt"
        tbl = read_domain_table(src_path)
        templates.append((domain, src_path, tbl))

    for lang in args.langs:
        lang = lang.strip()
        if not lang:
            continue
        if lang.upper() == "EN":
            continue

        target_dir = base_dir / lang
        for domain, src_path, tbl in templates:
            out_path = target_dir / f"{domain}_{lang}.txt"

            if out_path.exists() and not args.force:
                # Validate existing file for drift before skipping
                validate_existing_target(tbl, out_path, lang)
                print(f"Skipping existing (validated): {out_path}")
                continue

            prompt = build_translation_prompt(tbl.domain, lang, tbl.entries)
            print(f"Translating {tbl.domain} → {lang} ({len(tbl.entries)} keys)")

            translated = call_openai_translate(client, args.model, prompt)
            translated = validate_translation(tbl.entries, translated, lang)

            if args.dry_run:
                print(f"[dry-run] Would write: {out_path}")
            else:
                # Overwrite unconditionally when --force is set
                write_domain_table(out_path, tbl.domain, lang, translated)
                print(f"Wrote: {out_path}")

            time.sleep(max(0.0, args.sleep))

    print("Done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
