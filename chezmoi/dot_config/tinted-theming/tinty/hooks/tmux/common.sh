# Shared paths and repository operations (POSIX sh).
registry="$hook_dir/native-themes.json"
plugins="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty/native-repos"
warn() { printf 'Tinty tmux: %s\n' "$*" >&2; }
ensure_repo() (
  set -eu
  key=$1
  action=${2:-install}
  row=$(jq -ce --arg key "$key" '.repositories[] | select(.path == $key)' "$registry") || exit 1
  url=$(printf '%s' "$row" | jq -er '.url')
  revision=$(printf '%s' "$row" | jq -r '.revision // empty')
  dest="$plugins/$key"
  if [ -d "$dest/.git" ]; then
    [ "$(git -C "$dest" remote get-url origin)" = "$url" ] || exit 1
    if [ "$action" = install ]; then
      if [ -n "$revision" ]; then
        [ "$(git -C "$dest" rev-parse HEAD)" = "$(git -C "$dest" rev-parse "$revision^{commit}")" ] || exit 1
      fi
      exit 0
    fi
    [ -z "$(git -C "$dest" status --porcelain)" ] || exit 1
    if [ -n "$revision" ]; then
      git -C "$dest" fetch --tags origin && git -C "$dest" checkout --detach "$revision"
    else
      git -C "$dest" pull --ff-only
    fi
    exit $?
  fi
  [ ! -e "$dest" ] || exit 1
  mkdir -p "$(dirname "$dest")"
  tmp=$(mktemp -d "$dest.XXXXXX")
  trap 'rm -rf "$tmp"' EXIT
  trap 'exit 1' HUP INT TERM
  if [ -n "$revision" ]; then
    git clone --quiet --branch "$revision" -- "$url" "$tmp" || exit 1
  else
    git clone --quiet -- "$url" "$tmp" || exit 1
  fi
  # Another process may have installed the same repository.
  if [ -e "$dest" ]; then exit 1; fi
  mv "$tmp" "$dest"
)
