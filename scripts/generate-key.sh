#!/usr/bin/env bash
# Generate an SSH key pair at ~/.ssh/id_rsa_<LABEL> and register it with ssh-agent.
# LABEL is a free-form identifier (e.g. "github_myuser", "gcp_myuser").
# Host alias / IdentityFile binding is configured separately in ssh/config.d/.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: generate-key.sh [LABEL] [EMAIL]

Generate an SSH key pair at ~/.ssh/id_rsa_<LABEL>.

Arguments:
  LABEL    Key identifier suffix (e.g. github_myuser, gcp_myuser)
  EMAIL    Comment embedded in the key (typically your email)

Examples:
  ./generate-key.sh github_myuser my@email.com
  ./generate-key.sh gcp_myuser my@email.com
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -n "${1:-}" ]]; then
  LABEL="$1"
else
  read -rp "Enter key label (e.g. github_myuser): " LABEL
fi

if [[ -n "${2:-}" ]]; then
  EMAIL="$2"
else
  read -rp "Enter email (used as key comment): " EMAIL
fi

KEY_PATH="$HOME/.ssh/id_rsa_${LABEL}"

echo ""
echo "Configuration:"
echo "  Label:    $LABEL"
echo "  Email:    $EMAIL"
echo "  Key path: $KEY_PATH"
echo ""

if [[ -f "$KEY_PATH" ]]; then
  echo "Warning: SSH key already exists at $KEY_PATH"
  read -rp "Overwrite? (y/N): " overwrite
  if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
    echo "Using existing key"
    cat "${KEY_PATH}.pub"
    exit 0
  fi
  rm -f "$KEY_PATH" "${KEY_PATH}.pub"
fi

echo "Generating SSH key..."
ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f "$KEY_PATH" -N ""

if ! pgrep -x ssh-agent > /dev/null; then
  eval "$(ssh-agent -s)"
fi
ssh-add "$KEY_PATH" 2>/dev/null || true

echo ""
echo "SSH key generated: $KEY_PATH"
echo ""
echo "Public key:"
echo "========================================"
cat "${KEY_PATH}.pub"
echo "========================================"
