#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/context.sh"
source "$SCRIPTS_DIR/lib/link-nvim-config.sh"

VIM_FLAVOR="${VIM_FLAVOR:-lazy}"

link_nvim_config "$NVIM_DIR" "$VIM_FLAVOR"
