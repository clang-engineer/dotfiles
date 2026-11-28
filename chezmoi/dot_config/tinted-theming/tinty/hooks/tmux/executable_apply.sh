#!/bin/sh
set -eu
: "${TINTY_SCHEME_ID:?Tinty scheme is required}"
: "${TINTY_THEME_FILE_PATH:?Tinty tmux theme is required}"
hook_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$hook_dir/common.sh"
dir="${XDG_CONFIG_HOME:-$HOME/.config}/tinted-theming/tinty/generated"
mkdir -p "$dir"
palette=$(mktemp "$dir/tmux.conf.XXXXXX")
native=$(mktemp "$dir/tmux-native.conf.XXXXXX")
trap 'rm -f "$palette" "$native"' EXIT
trap 'exit 1' HUP INT TERM
cp "$TINTY_THEME_FILE_PATH" "$palette"

# Escape a path for a tmux double-quoted argument.
tmux_quote() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\$/\\$/g; s/`/\\`/g'; }
emit_run() {
  shell_path=$(printf '%s' "$2" | sed "s/'/'\\\\''/g")
  command="${1:+$1 }'$shell_path'"
  printf 'run-shell "%s"\n' "$(tmux_quote "$command")"
}
render_native() (
  case "$TINTY_SCHEME_ID" in base16-*|base24-*) scheme=${TINTY_SCHEME_ID#base??-} ;; *) exit 0 ;; esac
  row=$(jq -c --arg scheme "$scheme" 'first(.themes[] | select(.schemes | index($scheme))) // empty' "$registry") || exit 1
  [ -n "$row" ] || exit 0
  field() { printf '%s' "$row" | jq -r "$1"; }
  if [ "$(field '.requiresBash // empty')" = 4.2 ]; then
    bash -c '(( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 2) ))' || exit 1
  fi
  keys=$(field '.repository, .dependencies[]?') || exit 1
  for key in $keys; do ensure_repo "$key" install || exit 1; done
  entry=$(field '.entrypoint') || exit 1
  case "$entry" in *%s*) entry=$(printf "$entry" "$scheme" "$scheme") ;; esac
  plugin="$plugins/$entry"
  [ -f "$plugin" ] || exit 1
  option=$(field '.option // empty')
  variant=$(printf '%s' "$row" | jq -r --arg scheme "$scheme" '.variants[$scheme] // empty')
  if [ -n "$option" ]; then printf 'set -g %s %s\n' "$option" "$variant"; fi
  field '.before[]?' || exit 1
  case "$(field '.mode // "run"')" in
    source) printf 'source-file "%s"\n' "$(tmux_quote "$plugin")" ;;
    run) emit_run "$(field '.launcher // empty')" "$plugin" ;;
    *) exit 1 ;;
  esac
  field '.after[]?' || exit 1
  modules=$(field '.modules[]?') || exit 1
  for module in $modules; do
    [ -f "$plugins/$module" ] || exit 1
    emit_run "" "$plugins/$module"
  done
)
if ! render_native > "$native"; then
  warn "native theme unavailable for $TINTY_SCHEME_ID; using Tinted fallback"
  : > "$native"
fi
mv -f "$palette" "$dir/tmux.conf"
mv -f "$native" "$dir/tmux-native.conf"
if command -v tmux >/dev/null 2>&1 && tmux -N has-session 2>/dev/null; then
  if ! tmux -N source-file "$HOME/.tmux.conf"; then
    warn "reload failed; retrying without native theme"
    : > "$dir/tmux-native.conf"
    tmux -N source-file "$HOME/.tmux.conf"
  fi
fi
