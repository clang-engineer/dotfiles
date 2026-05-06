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

link_path "$REPO/scripts/.pgpass.example" "$HOME/.pgpass.example"

ensure_dir "$PGPASS_DIR"

if [[ ! -f "$PGPASS" ]]; then
  printf '→ Creating %s from template\n' "$PGPASS"
  cp "$REPO/scripts/.pgpass.example" "$PGPASS"
  chmod 600 "$PGPASS"
  printf '   Edit %s to fill in actual credentials.\n' "$PGPASS"
else
  printf '✓ %s already exists (skipping)\n' "$PGPASS"
fi
