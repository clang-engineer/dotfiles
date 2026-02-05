#!/bin/bash
# Create .nvim.lua link in current directory (Unix version)

SOURCE_FILE="$HOME/dotfiles/nvim-lua/unix.lua"
TARGET_FILE=".nvim.lua"

if [[ ! -f "$SOURCE_FILE" ]]; then
    echo "Source not found: $SOURCE_FILE" >&2
    exit 1
fi

rm -f "$TARGET_FILE"
ln -s "$SOURCE_FILE" "$TARGET_FILE"
echo "Created: $TARGET_FILE"
