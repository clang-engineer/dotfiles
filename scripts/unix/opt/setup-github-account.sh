#!/usr/bin/env bash

set -euo pipefail

# Setup GitHub account - integrated script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: setup-github-account.sh

Interactive setup for a new GitHub account.
This script will:
  1. Generate SSH key
  2. Add SSH config
  3. Setup Git includeIf for workspace

Example:
  ./setup-github-account.sh
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

echo "========================================="
echo "GitHub Account Setup"
echo "========================================="
echo ""

# Collect information
read -rp "Enter GitHub username: " USERNAME
read -rp "Enter GitHub email: " EMAIL
read -rp "Enter Git display name: " GIT_NAME
read -rp "Enter workspace path (e.g., ~/workspace/company): " WORKSPACE_PATH

# Expand tilde
WORKSPACE_PATH="${WORKSPACE_PATH/#\~/$HOME}"

echo ""
echo "Summary:"
echo "  GitHub Username: $USERNAME"
echo "  GitHub Email: $EMAIL"
echo "  Git Name: $GIT_NAME"
echo "  Workspace: $WORKSPACE_PATH"
echo ""
read -rp "Proceed? (Y/n): " confirm
if [[ "$confirm" =~ ^[Nn]$ ]]; then
  echo "Cancelled"
  exit 0
fi

echo ""
echo "========================================="
echo "Step 1: Generate SSH key"
echo "========================================="
"$SCRIPT_DIR/generate-ssh-key.sh" "$USERNAME" "$EMAIL"

echo ""
read -rp "Press Enter after adding the key to GitHub..."

echo ""
echo "========================================="
echo "Step 2: Add SSH config"
echo "========================================="
"$SCRIPT_DIR/add-ssh-config.sh" "$USERNAME"

echo ""
echo "========================================="
echo "Step 3: Setup Git includeIf"
echo "========================================="
"$SCRIPT_DIR/setup-git-includeif.sh" "$WORKSPACE_PATH" "$GIT_NAME" "$EMAIL"

echo ""
echo "========================================="
echo "All Done!"
echo "========================================="
echo ""
echo "Test SSH connection:"
echo "  ssh -T git@github.com-${USERNAME}"
echo ""
echo "Clone repository:"
echo "  git clone git@github.com-${USERNAME}:username/repo.git"
echo ""
echo "Update existing repository:"
echo "  git remote set-url origin git@github.com-${USERNAME}:username/repo.git"
echo ""
