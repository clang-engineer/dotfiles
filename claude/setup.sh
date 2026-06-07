#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO/scripts/lib/common.sh"

CLAUDE_DIR="$HOME/.claude"

if [[ -L "$CLAUDE_DIR" ]]; then
  printf '⚠︎ %s is a symlink (legacy whole-dir setup); skipping claude linking.\n' "$CLAUDE_DIR"
  printf '  Remove it manually, then rerun to migrate to per-file links.\n'
  exit 0
fi

ensure_dir "$CLAUDE_DIR"

link_path "$REPO/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

# settings.json: 템플릿에 머신별 경로를 주입하여 생성
generate_settings() {
  local dirs=()
  [[ -n "${BLOG_DIR:-}" ]]     && dirs+=("\"$BLOG_DIR\"")
  [[ -n "${TOOLBOX_DIR:-}" ]]  && dirs+=("\"$TOOLBOX_DIR\"")
  [[ -n "${DOTFILES_DIR:-}" ]] && dirs+=("\"$DOTFILES_DIR\"")

  local joined
  joined=$(printf '%s, ' "${dirs[@]}")
  joined="${joined%, }"

  sed "s|\"additionalDirectories\": \[\]|\"additionalDirectories\": [$joined]|" \
    "$REPO/claude/settings.json" > "$CLAUDE_DIR/settings.json"
  printf '→ Generated %s with directories: %s\n' "$CLAUDE_DIR/settings.json" "$joined"
}

if [[ -L "$CLAUDE_DIR/settings.json" ]]; then
  rm -f "$CLAUDE_DIR/settings.json"
fi
generate_settings

for d in commands hooks; do
  [[ -d "$REPO/claude/$d" ]] || continue
  link_path "$REPO/claude/$d" "$CLAUDE_DIR/$d"
done
