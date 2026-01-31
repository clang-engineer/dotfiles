#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${REPO_DIR:-}" ]]; then
  REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

SCRIPTS_DIR="$REPO_DIR/scripts"
HOME_SOURCE_DIR="$REPO_DIR/home"
CONFIGS_DIR="$REPO_DIR/configs"

export REPO_DIR SCRIPTS_DIR HOME_SOURCE_DIR CONFIGS_DIR
