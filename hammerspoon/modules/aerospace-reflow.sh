#!/bin/bash
# Move every open window back to its assigned workspace.
# Mapping is read from ~/.aerospace.toml (on-window-detected rules),
# so this stays a single source of truth with the auto-assign config.

AERO=/opt/homebrew/bin/aerospace
TOML=~/.aerospace.toml

# Build "bundle-id|workspace" map from the on-window-detected blocks
MAP=""
app=""
while IFS= read -r line; do
  case "$line" in
    '[[on-window-detected]]'*) app="" ;;
    'if.app-id'*) app="${line#*\'}"; app="${app%%\'*}" ;;
    'run'*)
      if [[ "$line" == *move-node-to-workspace* && -n "$app" ]]; then
        ws="${line#*move-node-to-workspace }"; ws="${ws%%\'*}"
        MAP="${MAP}${app}|${ws}"$'\n'
      fi
      app="" ;;
  esac
done < "$TOML"

# Move each window whose app has a home workspace
moved=0
while IFS='|' read -r wid bid; do
  target=$(printf '%s' "$MAP" | awk -F'|' -v b="$bid" '$1==b{print $2; exit}')
  [ -z "$target" ] && continue
  if "$AERO" move-node-to-workspace --window-id "$wid" --fail-if-noop "$target" 2>/dev/null; then
    moved=$((moved + 1))
  fi
done < <("$AERO" list-windows --all --format '%{window-id}|%{app-bundle-id}')

open -g "hammerspoon://aerospace-reflowed?moved=${moved}"
