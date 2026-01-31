#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/context.sh"
source "$SCRIPTS_DIR/lib/install-oh-my-zsh.sh"

install_oh_my_zsh
