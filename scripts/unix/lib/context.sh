#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${REPO_DIR:-}" ]]; then
  REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
fi

SCRIPTS_DIR="$REPO_DIR/scripts/unix"
HOME_SOURCE_DIR="$REPO_DIR/home"
NVIM_DIR="$REPO_DIR/nvim"

export REPO_DIR SCRIPTS_DIR HOME_SOURCE_DIR NVIM_DIR
