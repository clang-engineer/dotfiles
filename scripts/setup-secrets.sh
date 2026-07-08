#!/usr/bin/env bash
# Set per-machine environment variables in the ~/.secrets file.
# Skips variables that are already set.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/scripts/lib/common.sh"

link_path "$REPO/scripts/.secrets.example" "$HOME/.secrets.example"
link_path "$REPO/scripts/.secrets.ps1.example" "$HOME/.secrets.ps1.example"

SECRETS="$HOME/.secrets"

# Create the file if it doesn't exist
if [ ! -f "$SECRETS" ]; then
  printf '→ Creating %s\n' "$SECRETS"
  touch "$SECRETS"
  chmod 600 "$SECRETS"
fi

# If the variable isn't in the file, prompt the user and append it
ask_and_set() {
  var_name=$1
  description=$2
  default=$3

  if grep -q "^export ${var_name}=" "$SECRETS" 2>/dev/null; then
    printf '  ✓ %s already set\n' "$var_name"
    return
  fi

  printf '  %s (%s)\n' "$var_name" "$description"
  if [ -n "$default" ]; then
    printf '    default: %s\n' "$default"
  fi
  printf '    > '
  read -r val
  val="${val:-$default}"

  if [ -n "$val" ]; then
    echo "export ${var_name}=\"${val}\"" >> "$SECRETS"
    printf '    → saved\n'
  else
    printf '    → skipped\n'
  fi
}

printf '→ Checking ~/.secrets environment variables\n'
ask_and_set "WORKSPACE_DIR" "Workspace root directory" ""
ask_and_set "BLOG_DIR"      "Jekyll blog path" ""
ask_and_set "VAULT_DIR"   "Vault path"       ""
ask_and_set "DOTFILES_DIR"  "Dotfiles path"      ""
ask_and_set "DEVKIT_DIR"    "Devkit path (public reference)" ""
ask_and_set "PROFILE_DIR"   "GitHub profile README repo path" ""
ask_and_set "SECRETS_REPO"  "Private secrets repo (owner/repo, leave empty to skip overlay)" ""
ask_and_set "SECRETS_DIR"   "secrets repo clone path" "$HOME/workspace/secrets"

chmod 600 "$SECRETS"
