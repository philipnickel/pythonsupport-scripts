#!/bin/bash

set -euo pipefail

relative_path="${1:-}"
case "$relative_path" in
    Core/*.sh|Utils/*.sh) ;;
    *)
        echo "Launcher script path must be a safe Core/ or Utils/ .sh path: $relative_path" >&2
        exit 2
        ;;
esac
case "/$relative_path/" in
    */../*)
        echo "Launcher script path must not contain '..': $relative_path" >&2
        exit 2
        ;;
esac

bundle_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ -z "${PS_ENV:-}" && -z "${PS_BUNDLE_ROOT:-}" && -z "${PS_REPO_URL:-}" && -z "${PS_REPO_USER:-}" && -z "${PS_BRANCH:-}" && -z "${PS_FORGE_URL:-}" && -z "${PS_VSCODE_URL:-}" ]]; then
    export PS_ENV="offline"
    export PS_BUNDLE_ROOT="$bundle_root"
elif [[ "${PS_ENV:-}" == "offline" && -z "${PS_BUNDLE_ROOT:-}" ]]; then
    export PS_BUNDLE_ROOT="$bundle_root"
fi

# shellcheck source=/dev/null
source "$bundle_root/Core/env.sh"
run_repo_script "$relative_path"
