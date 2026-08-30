#!/bin/bash

set -euo pipefail

volume_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bundle_root="$volume_root/.dtu-python-support"
launcher="$bundle_root/pis-launcher"

if [[ ! -x "$launcher" ]]; then
    echo "DTU Python Support is incomplete: missing launcher." >&2
    echo "Please download or rebuild the complete disk image." >&2
    read -r -p "Press Enter to close..." _
    exit 1
fi

unset PS_OFFLINE PS_REPO_URL PS_REPO_USER PS_BRANCH PS_FORGE_URL PS_VSCODE_URL
unset PS_ENV_INITIALIZED PS_DTU_RELEASE PS_MINIFORGE_VERSION
export PS_ENV="offline"
export PS_BUNDLE_ROOT="$bundle_root"

exec "$launcher" --bundle-root "$bundle_root" "$@"
