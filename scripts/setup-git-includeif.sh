#!/usr/bin/env bash

set -euo pipefail

# Setup Git includeIf for workspace-specific user config

usage() {
  cat <<'EOF'
Usage: setup-git-includeif.sh [WORKSPACE_PATH] [GIT_NAME] [GIT_EMAIL]

Setup Git includeIf to use different user config per workspace.

Arguments:
  WORKSPACE_PATH    Path to workspace directory (e.g., ~/workspace/company)
  GIT_NAME          Git display name
  GIT_EMAIL         Git email

Examples:
  ./setup-git-includeif.sh
  ./setup-git-includeif.sh ~/workspace/company "John Doe" john@company.com
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

# Get workspace path
if [[ -n "${1:-}" ]]; then
  WORKSPACE_PATH="$1"
else
  read -rp "Enter workspace path (e.g., ~/workspace/company): " WORKSPACE_PATH
fi

# Expand tilde
WORKSPACE_PATH="${WORKSPACE_PATH/#\~/$HOME}"

# Get git name
if [[ -n "${2:-}" ]]; then
  GIT_NAME="$2"
else
  read -rp "Enter Git display name: " GIT_NAME
fi

# Get git email
if [[ -n "${3:-}" ]]; then
  GIT_EMAIL="$3"
else
  read -rp "Enter Git email: " GIT_EMAIL
fi

CONFIG_FILE="${WORKSPACE_PATH}/.gitconfig.inc"
GITCONFIG="$HOME/.gitconfig"

echo ""
echo "Configuration:"
echo "  Workspace: $WORKSPACE_PATH"
echo "  Git name: $GIT_NAME"
echo "  Git email: $GIT_EMAIL"
echo "  Config file: $CONFIG_FILE"
echo ""

# Create workspace directory if it doesn't exist
if [[ ! -d "$WORKSPACE_PATH" ]]; then
  mkdir -p "$WORKSPACE_PATH"
  echo "Created workspace directory: $WORKSPACE_PATH"
fi

# Create git config file
cat > "$CONFIG_FILE" <<EOF
[user]
    name = $GIT_NAME
    email = $GIT_EMAIL
EOF

echo "Created Git config file: $CONFIG_FILE"

# Check if includeIf already exists
if grep -q "gitdir:$WORKSPACE_PATH/" "$GITCONFIG" 2>/dev/null; then
  echo "includeIf entry already exists in $GITCONFIG"
else
  # Add includeIf to global gitconfig
  cat >> "$GITCONFIG" <<EOF

[includeIf "gitdir:$WORKSPACE_PATH/"]
    path = $CONFIG_FILE
EOF
  echo "Added includeIf entry to $GITCONFIG"
fi

echo ""
echo "Setup complete!"
echo ""
echo "Any Git repository under $WORKSPACE_PATH/ will use:"
echo "  name = $GIT_NAME"
echo "  email = $GIT_EMAIL"
echo ""
