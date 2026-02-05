#!/bin/bash
# Link .nvim.lua to current directory
# Usage: link-nvim.sh [target-directory]

TARGET_DIR="${1:-.}"
SOURCE_FILE="$HOME/dotfiles/.nvim.lua"
TARGET_FILE="$TARGET_DIR/.nvim.lua"

if [[ ! -f "$SOURCE_FILE" ]]; then
    echo "Error: Source file not found: $SOURCE_FILE" >&2
    exit 1
fi

if [[ -e "$TARGET_FILE" ]]; then
    echo "Removing existing .nvim.lua..."
    rm -f "$TARGET_FILE"
fi

ln -s "$SOURCE_FILE" "$TARGET_FILE"
echo "Symbolic link created: $TARGET_FILE -> $SOURCE_FILE"
