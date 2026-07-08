#!/bin/bash

# macOS Java version management automation script
# Creates symlinks for Homebrew-installed Java and configures jenv

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Java versions
JAVA_VERSIONS=("8" "11" "17" "21")

echo "🍵 Starting Java version setup..."

# Check jenv is installed
if ! command -v jenv &>/dev/null; then
  echo -e "${RED}✗ jenv is not installed.${NC}"
  echo "  Install it with: brew install jenv"
  exit 1
fi

# Create symlinks
echo ""
echo "📎 Creating symlinks..."
for version in "${JAVA_VERSIONS[@]}"; do
  # Find the Java path in the Homebrew Cellar
  JAVA_PATH=$(find /opt/homebrew/Cellar/openjdk@${version} -name "openjdk.jdk" 2>/dev/null | head -1 || true)

  if [ -z "$JAVA_PATH" ]; then
    echo -e "${YELLOW}⚠ openjdk@${version} is not installed. Skipping.${NC}"
    continue
  fi

  TARGET_PATH="/Library/Java/JavaVirtualMachines/openjdk-${version}.jdk"

  # Check for an existing link
  if [ -L "$TARGET_PATH" ]; then
    echo -e "${YELLOW}⚠ openjdk-${version}.jdk link already exists. Recreating.${NC}"
  fi

  # Create the symlink (requires sudo)
  sudo ln -sfn "$JAVA_PATH" "$TARGET_PATH"

  # Verify
  if /usr/libexec/java_home -v ${version} &>/dev/null; then
    JAVA_HOME=$(/usr/libexec/java_home -v ${version})
    echo -e "${GREEN}✓ Java ${version} link created: ${JAVA_HOME}${NC}"
  else
    echo -e "${RED}✗ Java ${version} link verification failed${NC}"
  fi
done

# Add Java versions to jenv
echo ""
echo "🔧 Adding Java versions to jenv..."

# Enable the jenv export plugin (if needed)
if ! jenv plugins | grep -q "export"; then
  echo "  Enabling jenv export plugin..."
  jenv enable-plugin export
fi

for version in "${JAVA_VERSIONS[@]}"; do
  JAVA_HOME=$(/usr/libexec/java_home -v ${version} 2>/dev/null || echo "")

  if [ -z "$JAVA_HOME" ]; then
    echo -e "${YELLOW}⚠ Could not find the home directory for Java ${version}. Skipping.${NC}"
    continue
  fi

  # Check whether it's already added to jenv
  if jenv versions | grep -q "${JAVA_HOME}"; then
    echo -e "${YELLOW}⚠ Java ${version} is already added to jenv.${NC}"
  else
    jenv add "$JAVA_HOME"
    echo -e "${GREEN}✓ Java ${version} added to jenv${NC}"
  fi
done

# Show the configured Java versions
echo ""
echo "📋 Configured Java versions:"
jenv versions

echo ""
echo -e "${GREEN}✨ Java version setup complete!${NC}"
echo ""
echo "Usage:"
echo "  Set global version: jenv global <version>"
echo "  Set local version:  jenv local <version>"
echo "  Show current:       jenv version"
