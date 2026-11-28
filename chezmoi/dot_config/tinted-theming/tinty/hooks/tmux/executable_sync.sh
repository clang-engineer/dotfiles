#!/bin/sh
set -eu
hook_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$hook_dir/common.sh"
case ${1:-} in
  --all) keys=$(jq -r '.repositories[].path' "$registry") ;;
  '') keys=$(jq -r '.repositories[].path' "$registry") ;;
  *) printf 'Usage: %s [--all]\n' "$0" >&2; exit 2 ;;
esac
failed=0
for key in $keys; do
  if [ "${1:-}" = --all ] || [ -d "$plugins/$key/.git" ]; then
    ensure_repo "$key" update || { warn "could not sync $key"; failed=1; }
  fi
done
exit "$failed"
