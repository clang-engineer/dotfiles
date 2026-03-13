#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO/scripts/lib/common.sh"

for f in "$REPO"/home/.*; do
  [[ -f "$f" ]] || continue
  link_path "$f" "$HOME/$(basename "$f")"
done

# non-dot file
link_path "$REPO/home/Microsoft.PowerShell_profile.ps1" \
  "$HOME/Microsoft.PowerShell_profile.ps1"
