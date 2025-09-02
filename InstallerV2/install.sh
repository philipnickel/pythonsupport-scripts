#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"

source "$ROOT_DIR/lib/logging.sh"
source "$ROOT_DIR/lib/config.sh"
source "$ROOT_DIR/lib/platform.sh"
source "$ROOT_DIR/lib/telemetry.sh"

source "$ROOT_DIR/phases/pre_install.sh"
source "$ROOT_DIR/phases/post_install.sh"

source "$ROOT_DIR/components/python.sh"
source "$ROOT_DIR/components/vscode.sh"
source "$ROOT_DIR/components/packages.sh"

source "$ROOT_DIR/lib/core.sh"

main_core "$@"

