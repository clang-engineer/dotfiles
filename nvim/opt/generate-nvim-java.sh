#!/bin/bash
# Create .nvim.lua for Java project in current directory
# Usage: generate-nvim-java.sh [jdtls_version] [gradle_version]

JDTLS="${1:-21}"
GRADLE="${2:-11}"

if [[ "$JDTLS" == "21" && "$GRADLE" == "11" ]]; then
    echo 'require("jvm-env").setup()' > .nvim.lua
else
    echo "require(\"jvm-env\").setup({ jdtls = \"$JDTLS\", gradle = \"$GRADLE\" })" > .nvim.lua
fi

echo "Created: .nvim.lua"
cat .nvim.lua
