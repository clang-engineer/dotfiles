#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
CONF="$REPO/webloc/bookmarks.conf"
APP_DIR="$HOME/Applications"

mkdir -p "$APP_DIR"
active_apps=()

while IFS='|' read -r name url; do
  [[ -z "$name" || "$name" == \#* ]] && continue

  app="$APP_DIR/$name.app"
  exe="$app/Contents/MacOS/$name"
  plist="$app/Contents/Info.plist"
  bundle_id="com.zero.bookmark.$(echo "$name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')"

  mkdir -p "$app/Contents/MacOS"

  cat > "$exe" << EOF
#!/bin/bash
open "$url"
EOF
  chmod +x "$exe"

  cat > "$plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$name</string>
    <key>CFBundleName</key>
    <string>$name</string>
    <key>CFBundleIdentifier</key>
    <string>$bundle_id</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
</dict>
</plist>
EOF

  printf '→ %s.app installed\n' "$name"
  active_apps+=("$name.app")
done < "$CONF"

# Remove apps not in bookmarks.conf
for app in "$APP_DIR"/*.app; do
  [[ -d "$app" ]] || continue
  app_name="$(basename "$app")"
  bundle_id=$(defaults read "$app/Contents/Info" CFBundleIdentifier 2>/dev/null || true)
  [[ "$bundle_id" == com.zero.bookmark.* ]] || continue
  found=false
  for active in "${active_apps[@]}"; do
    [[ "$app_name" == "$active" ]] && found=true && break
  done
  if [[ "$found" == false ]]; then
    rm -rf "$app"
    printf '✕ %s removed\n' "$app_name"
  fi
done
