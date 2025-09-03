#!/usr/bin/env bash
set -euo pipefail
IFS=$' \t\n'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/src/utilities/core.sh"

PIS_ENV=CI precheck::run | tee /tmp/precheck_ci.env
grep -q "ARCH=" /tmp/precheck_ci.env
grep -q "VERSION=" /tmp/precheck_ci.env
echo "Precheck test passed"

