#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export XDG_CACHE_HOME="$tmp/cache" XDG_CONFIG_HOME="$tmp/config"
mkdir -p "$tmp/bin" "$XDG_CACHE_HOME/tinted-theming/tinty" "$XDG_CONFIG_HOME/tinted-theming/tinty/hooks/tmux"
export PATH="$tmp/bin:$PATH"
cat > "$tmp/bin/tinty" <<'EOF'
#!/bin/sh
if [ "${2:-}" = --json ]; then
  printf '%s\n' '[{"id":"base16-fixture","system":"base16","variant":"dark"},{"id":"base24-fixture","system":"base24","variant":"light"},{"id":"base16-other","system":"base16","variant":"dark"}]'
else
  printf '%s\n' base16-fixture base24-fixture base16-other
fi
EOF
chmod +x "$tmp/bin/tinty"
cache="$XDG_CACHE_HOME/tinted-theming/tinty"
printf '%s\n' '{"items":[]}' > "$cache/radar-ranks.json"
printf '%s\n' '{"version":1,"families":{"fixture":{"stars":1234}},"schemes":{"base16-fixture":"fixture","base24-fixture":"fixture"}}' > "$cache/theme-families.json"
printf '%s\n' '{"themes":[{"schemes":["fixture"]}]}' > "$XDG_CONFIG_HOME/tinted-theming/tinty/hooks/tmux/native-themes.json"
src="$root/chezmoi/dot_config/fish/functions/__tinty_ranked_schemes.fish"
fish -n "$src"
fish -c 'source $argv[1]; __tinty_ranked_schemes' "$src" > "$tmp/result"
cat "$tmp/result"
test "$(wc -l < "$tmp/result" | tr -d ' ')" = 3
grep '^base16-fixture' "$tmp/result" | grep -F '1,234' | grep -F '[TMUX]'
grep '^base24-fixture' "$tmp/result" | grep -F '[light]' | grep -F '[base24]' | grep -F '[TMUX]'
if grep '^base16-other' "$tmp/result" | grep -F '[TMUX]'; then exit 1; fi
test "$(head -n 1 "$tmp/result" | cut -f1)" = base16-fixture
