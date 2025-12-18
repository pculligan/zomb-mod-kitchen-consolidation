#!/usr/bin/env bash
set -euo pipefail

# dev-symlink.sh
#
# Utility for managing Project Zomboid mod symlinks during development.
#
# Commands:
#   add    <mod_name> <dev_root> <zomboid_mods_dir>
#   remove <symlink_path>
#
# Examples:
#   ./dev-symlink.sh add kitchenconsolidation ~/dev ~/Zomboid/mods
#   ./dev-symlink.sh remove ~/Zomboid/mods/kitchenconsolidation
#

usage() {
  cat <<EOF
Usage:
  $0 add <mod_name> <dev_root> <zomboid_mods_dir>
  $0 remove <symlink_path>

Commands:
  add     Create or update a symlink for a mod.
  remove  Remove an existing symlink.

Notes:
  - 'add' is idempotent: existing symlinks will be replaced.
  - 'remove' only removes symlinks (will not delete real directories).
EOF
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

cmd="${1:-}"
shift || true

case "$cmd" in
  add)
    mod_name="${1:-}"
    dev_root="${2:-}"
    mods_dir="${3:-}"

    [[ -z "$mod_name" || -z "$dev_root" || -z "$mods_dir" ]] && usage && die "Missing arguments for add"

    dev_root="$(cd "$dev_root" && pwd)"
    mods_dir="$(cd "$mods_dir" && pwd)"

    src="${dev_root}/${mod_name}"
    dst="${mods_dir}/${mod_name}"

    [[ -d "$src" ]] || die "Dev source does not exist: $src"
    [[ -d "$mods_dir" ]] || die "Zomboid mods directory does not exist: $mods_dir"

    if [[ -L "$dst" ]]; then
      echo "Updating existing symlink: $dst"
      rm "$dst"
    elif [[ -e "$dst" ]]; then
      die "Destination exists and is not a symlink: $dst"
    fi

    ln -s "$src" "$dst"
    echo "Symlink created:"
    echo "  $dst -> $src"
    ;;

  remove)
    link_path="${1:-}"
    [[ -z "$link_path" ]] && usage && die "Missing symlink path for remove"

    if [[ -L "$link_path" ]]; then
      rm "$link_path"
      echo "Removed symlink: $link_path"
    elif [[ -e "$link_path" ]]; then
      die "Path exists but is not a symlink: $link_path"
    else
      die "No such symlink: $link_path"
    fi
    ;;

  *)
    usage
    die "Unknown command: $cmd"
    ;;
esac
