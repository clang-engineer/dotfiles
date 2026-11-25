# shellcheck shell=bash
# Clear variables listed as `export NAME=value` without executing the env file.
# This removes current values; it does not restore values from before sourcing.
# With no argument, pick a .env* file in the current directory using fzf.
env_unset() {
  if [ "$#" -gt 1 ]; then
    printf '%s\n' 'Usage: env_unset [FILE]' >&2
    return 2
  fi
  local __env_unset_file __env_unset_candidates
  if [ "$#" -eq 0 ]; then
    if ! command -v fzf >/dev/null 2>&1; then
      printf '%s\n' 'env_unset: fzf is required when no file is given' >&2
      return 1
    fi
    __env_unset_candidates=$(command find . ! -name . -prune -type f -name '.env*' -print) || return
    if [ -z "$__env_unset_candidates" ]; then
      printf '%s\n' 'env_unset: no .env* files in the current directory' >&2
      return 1
    fi
    __env_unset_file=$(printf '%s\n' "$__env_unset_candidates" | command fzf --no-multi --height=40% --reverse --prompt='env_unset> ') || return
  else
    __env_unset_file=$1
  fi
  if [ ! -f "$__env_unset_file" ] || [ ! -r "$__env_unset_file" ]; then
    printf '%s\n' 'env_unset: expected a readable file' >&2
    return 1
  fi
  local __env_unset_line __env_unset_name
  while IFS= read -r __env_unset_line || [ -n "$__env_unset_line" ]; do
    case "$__env_unset_line" in
      'export '*=*) ;;
      *) continue ;;
    esac
    __env_unset_name=${__env_unset_line#export }
    __env_unset_name=${__env_unset_name%%=*}
    case "$__env_unset_name" in
      '' | [0-9]* | *[!a-zA-Z0-9_]*) continue ;;
    esac
    builtin unset "$__env_unset_name" || return
  done <"$__env_unset_file"
}
