#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO/scripts/lib/common.sh"

# -- link configs --
for f in "$REPO"/zsh/.*; do
  [[ -f "$f" ]] || continue
  link_path "$f" "$HOME/$(basename "$f")"
done

# -- install (order matters: oh-my-zsh before plugins) --
sh "$REPO/zsh/install-oh-my-zsh.sh"
sh "$REPO/zsh/install-zsh-plugins.sh"

# -- secrets file (PC별 환경변수) --
if [[ ! -f "$HOME/.secrets" ]]; then
  echo ""
  echo "⚠︎ ~/.secrets 가 없습니다 (PC별 환경변수 미설정)"
  echo "  다음 명령으로 생성한 뒤 값을 채우세요:"
  echo "    cp $REPO/scripts/.secrets.example ~/.secrets && chmod 600 ~/.secrets"
  echo "    \$EDITOR ~/.secrets"
fi
