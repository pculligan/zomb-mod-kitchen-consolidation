#!/usr/bin/env python3
"""
bbcode.py

Convert a Markdown file to Steam-compatible BBCode.

Usage:
  python bbcode.py <source.md> <destination.bbcode>

Notes:
- Focuses on common Markdown used in Workshop descriptions
- Preserves links, lists, headings, bold/italic, code blocks
- Designed to be deterministic and readable, not a full Markdown parser

preview: https://daug32.github.io/SteamTextEditor/

"""

import sys
import re
from pathlib import Path

if len(sys.argv) != 3:
    print("Usage: python md_to_bbcode.py <source.md> <destination.bbcode>")
    sys.exit(1)

src = Path(sys.argv[1])
dst = Path(sys.argv[2])

text = src.read_text(encoding="utf-8")

# --- Headings ---
def repl_heading(match):
    level = len(match.group(1))
    content = match.group(2).strip()
    if level == 1:
        return f"[h1]{content}[/h1]\n"
    elif level == 2:
        return f"[h2]{content}[/h2]\n"
    elif level == 3:
        return f"[h3]{content}[/h3]\n"
    else:
        return content + "\n"

text = re.sub(r"^(#{1,6})\s+(.*)$", repl_heading, text, flags=re.MULTILINE)

# --- Bold / Italic ---
text = re.sub(r"\*\*(.*?)\*\*", r"[b]\1[/b]", text)
text = re.sub(r"\*(.*?)\*", r"[i]\1[/i]", text)

# --- Inline code ---
text = re.sub(r"`([^`]+)`", r"[code]\1[/code]", text)

# --- Links [text](url) ---
text = re.sub(r"\[(.*?)\]\((.*?)\)", r"[url=\2]\1[/url]", text)

# --- Horizontal rules ---
text = re.sub(r"^---+$", "", text, flags=re.MULTILINE)

# --- Lists ---
def convert_lists(lines):
    out = []
    in_list = False

    for line in lines:
        m = re.match(r"^\s*[-*+]\s+(.*)", line)
        if m:
            if not in_list:
                out.append("[list]")
                in_list = True
            out.append(f"[*]{m.group(1)}")
        else:
            if in_list:
                out.append("[/list]")
                in_list = False
            out.append(line)

    if in_list:
        out.append("[/list]")

    return out

lines = text.splitlines()
lines = convert_lists(lines)
text = "\n".join(lines)

# --- Numbered lists ---
def convert_numbered_lists(lines):
    out = []
    in_list = False

    for line in lines:
        m = re.match(r"^\s*\d+\.\s+(.*)", line)
        if m:
            if not in_list:
                out.append("[list=1]")
                in_list = True
            out.append(f"[*]{m.group(1)}")
        else:
            if in_list:
                out.append("[/list]")
                in_list = False
            out.append(line)

    if in_list:
        out.append("[/list]")

    return out

lines = text.splitlines()
lines = convert_numbered_lists(lines)
text = "\n".join(lines)

# --- Cleanup excessive blank lines ---
text = re.sub(r"\n{3,}", "\n\n", text)

# Write output
dst.parent.mkdir(parents=True, exist_ok=True)
dst.write_text(text.strip() + "\n", encoding="utf-8")

print(f"Converted {src} -> {dst}")
