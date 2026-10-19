#!/bin/bash
# Usage: aerospace-move-node.sh <workspace>
# Capture the focused window once; report failures instead of silently ignoring them.

AERO=/opt/homebrew/bin/aerospace
WS="$1"

notify() {
  /usr/bin/open -g "hammerspoon://aerospace-node-moved?ws=${WS}&status=$1&app=$2"
}

if ! WINDOW=$("$AERO" list-windows --focused --format '%{window-id}|%{app-name}'); then
  notify failed ""
  exit 1
fi

if [ -z "$WINDOW" ]; then
  notify empty ""
  exit 0
fi

WINDOW_ID=${WINDOW%%|*}
APP=${WINDOW#*|}
# Escape URL delimiters as well as spaces in application names.
APP=${APP//%/%25}
APP=${APP//&/%26}
APP=${APP//#/%23}
APP=${APP//\?/%3F}
APP=${APP// /%20}

if ! "$AERO" move-node-to-workspace --window-id "$WINDOW_ID" "$WS"; then
  notify failed "$APP"
  exit 1
fi

notify moved "$APP"
