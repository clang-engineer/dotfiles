#!/usr/bin/env bash
# ~/.pgpass 파일을 준비한다.
# 이미 있으면 건드리지 않고, 없으면 example을 복사한다.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/scripts/lib/common.sh"

# Windows(Git Bash)와 Unix의 경로가 다름
if [[ -n "${APPDATA:-}" ]]; then
  PGPASS_DIR="$APPDATA/postgresql"
  PGPASS="$PGPASS_DIR/pgpass.conf"
else
  PGPASS_DIR="$HOME"
  PGPASS="$HOME/.pgpass"
fi

ensure_dir "$PGPASS_DIR"

if [[ ! -f "$PGPASS" ]]; then
  cp "$REPO/home/pgpass.example" "$PGPASS"
  chmod 600 "$PGPASS"
  printf '→ Created %s\n' "$PGPASS"
  printf '\n  ⚠ NEXT: edit the file above and replace each CHANGE_ME\n'
  printf '    with the real password.\n\n'
else
  printf '✓ %s already exists (skipping)\n' "$PGPASS"
fi
