#!/usr/bin/env bash

set -euo pipefail

# Add GitHub host to SSH config

usage() {
  cat <<'EOF'
Usage: add-ssh-config.sh [USERNAME]

Add GitHub host configuration to ~/.ssh/config

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

HOST_ALIAS="github.com-${USERNAME}"
KEY_PATH="$HOME/.ssh/id_rsa_github_${USERNAME}"
SSH_CONFIG="$HOME/.ssh/config"

echo ""
echo "Configuration:"
echo "  Host alias: $HOST_ALIAS"
echo "  Key path: $KEY_PATH"
echo ""

# Check if key exists
if [[ ! -f "$KEY_PATH" ]]; then
  echo "Error: SSH key not found at $KEY_PATH"
  echo "Run generate-ssh-key.sh first"
  exit 1
fi

# Create SSH config if it doesn't exist
if [[ ! -f "$SSH_CONFIG" ]]; then
  touch "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"
fi

# Check if host already exists
if grep -q "^Host $HOST_ALIAS$" "$SSH_CONFIG"; then
  echo "Host $HOST_ALIAS already exists in SSH config"
  exit 0
fi

# Add new host entry
cat >> "$SSH_CONFIG" <<EOF

# GitHub account - $USERNAME
Host $HOST_ALIAS
    HostName github.com
    User git
    IdentityFile $KEY_PATH
EOF

echo "SSH config updated successfully!"
echo ""
echo "You can now use this host alias in git commands:"
echo "  git clone git@${HOST_ALIAS}:username/repo.git"
echo "  git remote set-url origin git@${HOST_ALIAS}:username/repo.git"
echo ""
