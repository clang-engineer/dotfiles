#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO/scripts/lib/common.sh"

CLAUDE_DIR="$HOME/.claude"

# settings.json: 템플릿(settings.template.json)에 머신별 경로를 주입해 생성.
# additionalDirectories는 env 확장이 안 되므로 절대경로를 여기서 박아 넣는다.
# 생성물(settings.json)은 gitignore 대상 — 머신 경로가 repo에 커밋되지 않게 한다.
generate_settings() {
  local dirs=()
  [[ -n "${BLOG_DIR:-}" ]]     && dirs+=("\"$BLOG_DIR\"")
  [[ -n "${TOOLBOX_DIR:-}" ]]  && dirs+=("\"$TOOLBOX_DIR\"")
  [[ -n "${DOTFILES_DIR:-}" ]] && dirs+=("\"$DOTFILES_DIR\"")

  local joined
  joined=$(printf '%s, ' "${dirs[@]}")
  joined="${joined%, }"

  sed "s|\"additionalDirectories\": \[\]|\"additionalDirectories\": [$joined]|" \
    "$REPO/claude/settings.template.json" > "$CLAUDE_DIR/settings.json"
  printf '→ Generated %s with directories: %s\n' "$CLAUDE_DIR/settings.json" "$joined"
}

# whole-dir 심링크(~/.claude → repo/claude): 파일은 이미 제자리라 링크 불필요.
# 단 settings.json은 템플릿에서 생성해야 하므로 그것만 처리하고 종료.
if [[ -L "$CLAUDE_DIR" ]]; then
  generate_settings
  exit 0
fi

ensure_dir "$CLAUDE_DIR"
link_path "$REPO/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
link_path "$REPO/claude/statusline.sh" "$CLAUDE_DIR/statusline.sh"

if [[ -L "$CLAUDE_DIR/settings.json" ]]; then
  rm -f "$CLAUDE_DIR/settings.json"
fi
generate_settings

for d in commands hooks; do
  [[ -d "$REPO/claude/$d" ]] || continue
  link_path "$REPO/claude/$d" "$CLAUDE_DIR/$d"
done
