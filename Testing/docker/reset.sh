#!/usr/bin/env bash
# Reset the Windows-like test container to a clean state.
# Destroys the container and recreates it fresh from the image.
# The repo mount (/repo) is unaffected — only in-container state is wiped.
set -euo pipefail

CONTAINER="ps-windows-test"

docker rm -f "$CONTAINER" >/dev/null 2>&1 && echo "Removed container $CONTAINER" || true

# Recreate via run.sh (drops you into a fresh pwsh shell)
"$(dirname "${BASH_SOURCE[0]}")/run.sh" "$@"
