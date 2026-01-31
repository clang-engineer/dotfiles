#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/context.sh"
source "$SCRIPTS_DIR/lib/link-dotfiles.sh"

link_dotfiles "$HOME_SOURCE_DIR"
