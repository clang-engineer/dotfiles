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
registry="$config_home/tinted-theming/tinty/tmux-native-themes.json"
if [ -r "$registry" ]; then
  row=$(jq -r --arg scheme "$scheme" '
    first(.themes[] | select(.schemes | index($scheme))) |
    [.entrypoint, (.option // ""), (.variant // ""), (.mode // "run"), (.launcher // "")] |
    join("|")
  ' "$registry") || exit 1
  if [ -n "$row" ]; then
    IFS='|' read -r entry option rule mode shell <<EOF
$row
EOF
    case "$entry" in
      *%s*) plugin="$plugins/$(printf "$entry" "$scheme" "$scheme")" ;;
      *) plugin="$plugins/$entry" ;;
    esac
    launcher=${shell:+$shell }
    case "$rule" in
      suffix) variant=${scheme##*-} ;;
      rose-pine)
        variant=${scheme#rose-pine}
        variant=${variant#-}
        variant=${variant:-main} ;;
      gruvbox) variant=${scheme#gruvbox-}256 ;;
      everforest)
        variant=${scheme#everforest-}
        [ "$variant" = "$scheme" ] && variant=dark-medium ;;
      scheme) variant=$scheme ;;
    esac
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
  if [ "$option" = @catppuccin_flavor ]; then
    printf '%s\n' 'set -g @catppuccin_reset true' >> "$tmp"
  fi
  if [ "$mode" = source ]; then
    # The Nightfox project ships tmux config files, not executable entrypoints.
    quoted=$(printf '%s' "$plugin" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\$/\\$/g; s/`/\\`/g')
    printf 'source-file "%s"\n' "$quoted" >> "$tmp"
  else
    # Quote for the tmux parser and the shell invoked by run-shell.
    quoted=$(printf '%s' "$plugin" | sed "s/'/'\\\\''/g")
    printf "run-shell \"%s'%s'\"\n" "$launcher" "$quoted" >> "$tmp"
  fi
  if [ "$option" = @catppuccin_flavor ]; then
    printf '%s\n' 'set -g status-left "#{E:@catppuccin_status_session}"' \
      'set -g status-right "#{E:@catppuccin_status_application}"' >> "$tmp"
  fi
fi
mv -f "$tmp" "$dir/tmux-native.conf"

# Reload OMT first so a previous plugin cannot leak its status layout into the fallback.
if command -v tmux >/dev/null 2>&1 && tmux -N has-session 2>/dev/null; then
  tmux -N source-file "$HOME/.tmux.conf"
fi
