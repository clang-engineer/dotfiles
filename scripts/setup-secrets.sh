#!/usr/bin/env bash
# ~/.secrets 파일에 머신별 환경변수를 설정한다.
# 이미 설정된 변수는 건너뛴다.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/scripts/lib/common.sh"

link_path "$REPO/scripts/.secrets.example" "$HOME/.secrets.example"
link_path "$REPO/scripts/.secrets.ps1.example" "$HOME/.secrets.ps1.example"

SECRETS="$HOME/.secrets"

# 파일이 없으면 생성
if [ ! -f "$SECRETS" ]; then
  printf '→ Creating %s\n' "$SECRETS"
  touch "$SECRETS"
  chmod 600 "$SECRETS"
fi

# 변수가 파일에 없으면 사용자에게 물어보고 추가
ask_and_set() {
  var_name=$1
  description=$2
  default=$3

  if grep -q "^export ${var_name}=" "$SECRETS" 2>/dev/null; then
    printf '  ✓ %s already set\n' "$var_name"
    return
  fi

  printf '  %s (%s)\n' "$var_name" "$description"
  if [ -n "$default" ]; then
    printf '    default: %s\n' "$default"
  fi
  printf '    > '
  read -r val
  val="${val:-$default}"

  if [ -n "$val" ]; then
    echo "export ${var_name}=\"${val}\"" >> "$SECRETS"
    printf '    → saved\n'
  else
    printf '    → skipped\n'
  fi
}

printf '→ Checking ~/.secrets environment variables\n'
ask_and_set "WORKSPACE_DIR" "작업 디렉토리 루트" ""
ask_and_set "BLOG_DIR"      "Jekyll 블로그 경로" ""
ask_and_set "VAULT_DIR"   "Vault 경로"       ""
ask_and_set "DOTFILES_DIR"  "Dotfiles 경로"      ""
ask_and_set "DEVKIT_DIR"    "Devkit 경로 (공개 레퍼런스)" ""
ask_and_set "PROFILE_DIR"   "GitHub 프로필 README repo 경로" ""
ask_and_set "SECRETS_REPO"  "Private secrets repo (owner/repo, 비우면 overlay 스킵)" ""
ask_and_set "SECRETS_DIR"   "secrets repo 클론 경로" "$HOME/Desktop/_zero/private/secrets"

chmod 600 "$SECRETS"
