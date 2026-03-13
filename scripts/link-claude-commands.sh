#!/usr/bin/env bash
#
# Link shared Claude Code custom commands into a project.
#
# Usage:
#   ./scripts/link-claude-commands.sh <project-path> [command1 command2 ...]
#   ./scripts/link-claude-commands.sh --force <project-path> [command1 ...]
#
# - No command names → link all .md files
# - Specific names   → link only those (omit .md extension)

set -euo pipefail

# Enable native symlinks on Windows (Git Bash / MSYS2)
export MSYS=winsymlinks:nativestrict

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

DOTFILES_COMMANDS="$(cd "$SCRIPT_DIR/../claude/commands" && pwd)"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--force] <project-path> [command1 command2 ...]

Link Claude Code custom commands from dotfiles into a project.
  --force        Overwrite existing files/symlinks
  <project-path> Target project root
  [commands]     Specific command names (without .md); omit for all
EOF
  exit 1
}

# --- parse args ---
if [[ "${1:-}" == "--force" ]]; then
  FORCE=true
  export FORCE
  shift
fi

[[ $# -lt 1 ]] && usage

PROJECT_PATH="$1"
shift

if [[ ! -d "$PROJECT_PATH" ]]; then
  printf 'Error: %s is not a directory\n' "$PROJECT_PATH" >&2
  exit 1
fi

TARGET_DIR="$PROJECT_PATH/.claude/commands"
ensure_dir "$TARGET_DIR"

# --- resolve absolute paths ---
DOTFILES_COMMANDS="$(cd "$DOTFILES_COMMANDS" && pwd -W 2>/dev/null || pwd)"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd -W 2>/dev/null || pwd)"

# --- collect source files ---
if [[ $# -gt 0 ]]; then
  FILES=()
  for name in "$@"; do
    f="$DOTFILES_COMMANDS/${name}.md"
    if [[ ! -f "$f" ]]; then
      printf 'Warning: %s.md not found in %s; skipping\n' "$name" "$DOTFILES_COMMANDS" >&2
      continue
    fi
    FILES+=("$f")
  done
else
  FILES=("$DOTFILES_COMMANDS"/*.md)
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No commands to link." >&2
  exit 1
fi

# --- link each command ---
for src in "${FILES[@]}"; do
  basename="$(basename "$src")"
  link_path "$src" "$TARGET_DIR/$basename"
done
