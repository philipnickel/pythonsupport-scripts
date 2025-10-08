#!/usr/bin/env bash
set -euo pipefail
IFS=$' \t\n'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/src/utilities/core.sh"
source "$ROOT_DIR/src/etc/config.sh"
source "$ROOT_DIR/src/components/vscode/install.sh"

DRY_RUN=true
vscode::install
vscode::verify
echo "VS Code component test passed (dry-run)"

