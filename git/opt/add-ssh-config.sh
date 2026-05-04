#!/usr/bin/env bash

set -euo pipefail

# Add SSH config entry for GitHub account

usage() {
  cat <<'EOF'
Usage: add-ssh-config.sh [USERNAME]

Add SSH config entry for a GitHub account.

Arguments:
  USERNAME    GitHub username (optional, will prompt if not provided)

Examples:
  ./add-ssh-config.sh
  ./add-ssh-config.sh myusername
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

# Get username
if [[ -n "${1:-}" ]]; then
  USERNAME="$1"
else
  read -rp "Enter GitHub username: " USERNAME
fi

SSH_CONFIG="$HOME/.ssh/config"
HOST_ALIAS="github.com-${USERNAME}"
KEY_PATH="$HOME/.ssh/id_rsa_github_${USERNAME}"

# Ensure .ssh directory and config file exist
mkdir -p "$HOME/.ssh"
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

# Check if entry already exists
if grep -q "Host ${HOST_ALIAS}" "$SSH_CONFIG" 2>/dev/null; then
  echo "⚠︎ SSH config entry for '${HOST_ALIAS}' already exists"
  exit 0
fi

# Append entry
cat >> "$SSH_CONFIG" <<EOF

# GitHub: ${USERNAME}
Host ${HOST_ALIAS}
  HostName github.com
  User git
  IdentityFile ${KEY_PATH}
  IdentitiesOnly yes
EOF

echo "✓ Added SSH config entry: ${HOST_ALIAS}"
