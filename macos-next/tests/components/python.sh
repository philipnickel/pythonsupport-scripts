#!/usr/bin/env bash
set -euo pipefail
IFS=$' \t\n'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/src/utilities/core.sh"
source "$ROOT_DIR/src/etc/config.sh"
source "$ROOT_DIR/src/components/python/miniforge.sh"
source "$ROOT_DIR/src/components/python/dtu_base_env.sh"

DRY_RUN=true
[[ "$(python::miniforge::detect)" == "present" || "$(python::miniforge::detect)" == "absent" ]]
python::miniforge::install
python::base_env::ensure
echo "Python component test passed (dry-run)"

