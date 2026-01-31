#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/context.sh"
source "$SCRIPTS_DIR/lib/install-zsh-plugins.sh"

install_zsh_plugins
