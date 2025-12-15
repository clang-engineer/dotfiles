#!/usr/bin/env bash

set -euo pipefail

# Generate SSH key for GitHub account

usage() {
  cat <<'EOF'
Usage: generate-ssh-key.sh [USERNAME] [EMAIL]

Generate SSH key pair for GitHub account.

Arguments:
  USERNAME    GitHub username (optional, will prompt if not provided)
  EMAIL       GitHub email (optional, will prompt if not provided)

Examples:
  ./generate-ssh-key.sh
  ./generate-ssh-key.sh myusername my@email.com
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

# Get email
if [[ -n "${2:-}" ]]; then
  EMAIL="$2"
else
  read -rp "Enter GitHub email: " EMAIL
fi

KEY_NAME="id_rsa_github_${USERNAME}"
KEY_PATH="$HOME/.ssh/${KEY_NAME}"

echo ""
echo "Configuration:"
echo "  Username: $USERNAME"
echo "  Email: $EMAIL"
echo "  Key path: $KEY_PATH"
echo ""

# Check if key already exists
if [[ -f "$KEY_PATH" ]]; then
  echo "Warning: SSH key already exists at $KEY_PATH"
  read -rp "Overwrite? (y/N): " overwrite
  if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
    echo "Using existing key"
    cat "${KEY_PATH}.pub"
    exit 0
  fi
fi

# Generate SSH key
echo "Generating SSH key..."
ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f "$KEY_PATH" -N ""

# Add to ssh-agent
if ! pgrep -x ssh-agent > /dev/null; then
  eval "$(ssh-agent -s)"
fi
ssh-add "$KEY_PATH" 2>/dev/null || true

echo ""
echo "SSH key generated successfully!"
echo ""
echo "Public key (add this to GitHub):"
echo "========================================"
cat "${KEY_PATH}.pub"
echo "========================================"
echo ""
echo "Add this key to: https://github.com/settings/keys"
echo ""
