#!/bin/sh
set -eu

: "${TINTY_SCHEME_ID:?Tinty scheme is required}"
: "${TINTY_THEME_FILE_PATH:?Tinty tmux theme is required}"
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
dir="$config_home/tinted-theming/tinty/generated"
plugins="$config_home/tmux/plugins"
mkdir -p "$dir"
cp -f "$TINTY_THEME_FILE_PATH" "$dir/tmux.conf"

plugin=
option=
variant=
launcher=
mode=run
case "$TINTY_SCHEME_ID" in
  base16-*|base24-*) scheme=${TINTY_SCHEME_ID#base??-} ;;
  *) scheme= ;;
esac
registry="$(dirname "$0")/native-themes.json"
if [ -r "$registry" ]; then
  row=$(jq -c --arg scheme "$scheme" 'first(.themes[] | select(.schemes | index($scheme))) // empty' "$registry") || exit 1
  if [ -n "$row" ]; then
    entry=$(printf '%s' "$row" | jq -r '.entrypoint')
    option=$(printf '%s' "$row" | jq -r '.option // ""')
    variant=$(printf '%s' "$row" | jq -r --arg scheme "$scheme" '.variants[$scheme] // ""')
    mode=$(printf '%s' "$row" | jq -r '.mode // "run"')
    shell=$(printf '%s' "$row" | jq -r '.launcher // ""')
    launcher=${shell:+$shell }
    case "$entry" in
      *%s*) plugin="$plugins/$(printf "$entry" "$scheme" "$scheme")" ;;
      *) plugin="$plugins/$entry" ;;
    esac
    if [ "$(printf '%s' "$row" | jq -r '.requiresBash // ""')" = 4.2 ]; then
      if ! bash -c '(( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 2) ))' 2>/dev/null; then
        printf '%s\n' 'Tinty tmux: Bash 4.2+ required; using fallback.' >&2
        plugin=
      fi
    fi
  fi
fi

if [ -n "$plugin" ] && [ ! -f "$plugin" ]; then
  printf 'Tinty tmux: missing native theme %s; run chezmoi apply first.\n' "$plugin" >&2
  plugin=
fi

tmp=$(mktemp "$dir/tmux-native.conf.XXXXXX") || exit 1
trap 'rm -f "$tmp"' EXIT HUP INT TERM
if [ -n "$plugin" ]; then
  if [ -n "$option" ]; then
    printf 'set -g %s %s\n' "$option" "$variant" > "$tmp"
  fi
  printf '%s' "$row" | jq -r '.before[]?' >> "$tmp"
  if [ "$mode" = source ]; then
    # The Nightfox project ships tmux config files, not executable entrypoints.
    quoted=$(printf '%s' "$plugin" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\$/\\$/g; s/`/\\`/g')
    printf 'source-file "%s"\n' "$quoted" >> "$tmp"
  else
    # Quote for the tmux parser and the shell invoked by run-shell.
    quoted=$(printf '%s' "$plugin" | sed "s/'/'\\\\''/g")
    printf "run-shell \"%s'%s'\"\n" "$launcher" "$quoted" >> "$tmp"
  fi
  printf '%s' "$row" | jq -r '.after[]?' >> "$tmp"
fi
mv -f "$tmp" "$dir/tmux-native.conf"

# Reload OMT first so a previous plugin cannot leak its status layout into the fallback.
if command -v tmux >/dev/null 2>&1 && tmux -N has-session 2>/dev/null; then
  tmux -N source-file "$HOME/.tmux.conf"
fi
