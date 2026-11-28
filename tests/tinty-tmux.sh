#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
src="$root/chezmoi/dot_config/tinted-theming/tinty/hooks/tmux"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/config" XDG_DATA_HOME="$tmp/data"
mkdir -p "$HOME" "$tmp/hooks" "$tmp/origin"
cp "$src/common.sh" "$tmp/hooks/"
cp "$src/executable_apply.sh" "$tmp/hooks/apply.sh"
cp "$src/executable_sync.sh" "$tmp/hooks/sync.sh"
for f in "$tmp/hooks/"*.sh; do sh -n "$f"; done
git init -q "$tmp/origin"
printf 'set -g status-left fixture\n' > "$tmp/origin/theme.conf"
git -C "$tmp/origin" add .
git -C "$tmp/origin" -c user.name=Test -c user.email=test@example.invalid commit -qm fixture
git -C "$tmp/origin" tag v1
jq -n --arg url "file://$tmp/origin" '{repositories:[{path:"fixture/theme",url:$url,revision:"v1"}],themes:[{schemes:["fixture"],repository:"fixture/theme",entrypoint:"fixture/theme/theme.conf",mode:"source"}]}' > "$tmp/hooks/native-themes.json"
export TINTY_THEME_FILE_PATH="$tmp/palette" TINTY_SCHEME_ID=base16-fixture
printf 'set -g status-right palette\n' > "$TINTY_THEME_FILE_PATH"
sh "$tmp/hooks/apply.sh"
cache="$XDG_DATA_HOME/tinted-theming/tinty/native-repos/fixture/theme"
out="$XDG_CONFIG_HOME/tinted-theming/tinty/generated"
test -f "$cache/theme.conf"
grep -F "$cache/theme.conf" "$out/tmux-native.conf"
cmp "$TINTY_THEME_FILE_PATH" "$out/tmux.conf"
sh "$tmp/hooks/apply.sh"
sh "$tmp/hooks/sync.sh"
printf dirty >> "$cache/theme.conf"
if sh "$tmp/hooks/sync.sh"; then echo 'dirty update unexpectedly succeeded' >&2; exit 1; fi
git -C "$cache" checkout -- theme.conf
TINTY_SCHEME_ID=base16-unsupported sh "$tmp/hooks/apply.sh"
test ! -s "$out/tmux-native.conf"
rm "$cache/theme.conf"
sh "$tmp/hooks/apply.sh"
test ! -s "$out/tmux-native.conf"
git -C "$cache" checkout -- theme.conf
sh "$tmp/hooks/apply.sh"
# Real isolated tmux server: verify generated files parse and apply.
tmux -L tinty-test-$$ -f /dev/null new-session -d
trap 'tmux -L tinty-test-$$ kill-server 2>/dev/null || :; rm -rf "$tmp"' EXIT
tmux -L tinty-test-$$ source-file "$out/tmux.conf"
tmux -L tinty-test-$$ source-file "$out/tmux-native.conf"
test "$(tmux -L tinty-test-$$ show-option -gv status-left)" = fixture
test "$(tmux -L tinty-test-$$ show-option -gv status-right)" = palette
echo 'Native tmux hook tests passed'
