#!/usr/bin/env bash
set -euo pipefail

# package.sh
#
# Assemble a Project Zomboid Workshop upload directory.
#
# Usage:
#   ./scripts/package.sh <modid> <repo_root> <zomboid_workshop_root>
#
# Example:
#   ./scripts/package.sh kitchenconsolidation \
#       ~/work/zomb-mod-kitchen-consolidation \
#       ~/Zomboid/workshop
#

usage() {
  cat <<EOF
Usage:
  $0 <modid> <repo_root> <zomboid_workshop_root>

Arguments:
  modid                 Mod ID / folder name (e.g. kitchenconsolidation)
  repo_root             Root of the mod repository
  zomboid_workshop_root Typically ~/Zomboid/Workshop

The script creates:
  <zomboid_workshop_root>/<modid>/
    ├── Contents/mods/<modid>/
    │   ├── media/
    │   └── mod.info
    ├── poster.png
    ├── preview.png
    └── workshop.txt
EOF
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

modid="${1:-}"
repo_root="${2:-}"
workshop_root="${3:-}"

[[ -z "$modid" || -z "$repo_root" || -z "$workshop_root" ]] && usage && die "Missing arguments"

repo_root="$(cd "$repo_root" && pwd)"
workshop_root="$(cd "$workshop_root" && pwd)"

src_mod="${repo_root}/${modid}"
dst_root="${workshop_root}"
dst_contents="${dst_root}/${modid}/Contents/mods/${modid}"

# --- Validate inputs ---
[[ -f "${src_mod}/mod.info" ]] || die "mod.info not found in repo root"
[[ -d "${src_mod}/media" ]] || die "media/ not found in repo root"
[[ -f "${repo_root}/workshop/description.bbcode" ]] || die "Missing workshop/description.bbcode"
[[ -f "${src_mod}/poster.png" ]] || die "Missing ${src_mod}/poster.png"

echo "Packaging mod '${modid}'"
echo "Repo:      ${repo_root}"
echo "Workshop:  ${dst_root}"

# --- Clean previous package ---
rm -rf "${dst_root}"
mkdir -p "${dst_contents}"

# --- Copy mod payload ---
rsync -av \
  --exclude='.git*' \
  --exclude='*.md' \
  --exclude='scripts/' \
  --exclude='workshop/' \
  "${src_mod}/" \
  "${dst_contents}/"

# --- Copy workshop metadata ---
cp "${src_mod}/poster.png" "${dst_root}/${modid}/preview.png"
cp "${repo_root}/workshop/description.bbcode" "${dst_root}/workshop.txt"

# --- Remove macOS junk ---
find "${dst_root}/${modid}/Contents/" -name ".DS_Store" -delete


echo "Workshop package assembled at:"
echo "  ${dst_root}"

echo
echo "You can now upload this folder via the Project Zomboid Workshop uploader."
