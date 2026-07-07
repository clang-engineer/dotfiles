#!/usr/bin/env bash
# Overlay the private secrets repo (ssh host configs, nvim db connections) after
# chezmoi has fetched it via .chezmoiexternal. No-op when secrets are absent:
# a public clone with no SECRETS_DIR, or a clone that failed for lack of access.
set -euo pipefail
[ -f "$HOME/.secrets" ] && . "$HOME/.secrets"

if [ -n "${SECRETS_DIR:-}" ] && [ -f "$SECRETS_DIR/setup.sh" ]; then
  sh "$SECRETS_DIR/setup.sh"
else
  printf '→ secrets overlay skipped (no SECRETS_DIR/setup.sh)\n'
fi
