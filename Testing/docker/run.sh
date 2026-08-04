#!/usr/bin/env bash
# Start (or attach to) the Windows-like PowerShell test container.
# The repo root is mounted at /repo inside the container.
#
# Usage:
#   Testing/docker/run.sh                 # interactive pwsh shell
#   Testing/docker/run.sh -File Core/VsCode/config/settings_windows.ps1
set -euo pipefail

IMAGE="ps-windows-test"
CONTAINER="ps-windows-test"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Build image if missing
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "Building image $IMAGE..."
    docker build -t "$IMAGE" -f "$REPO_ROOT/Testing/docker/Dockerfile.windows" "$REPO_ROOT/Testing/docker"
fi

# Start container if missing or stopped (kept alive with sleep)
if ! docker ps -q -f "name=^${CONTAINER}$" | grep -q .; then
    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
    docker run -d --name "$CONTAINER" -v "$REPO_ROOT:/repo" --entrypoint sleep "$IMAGE" infinity >/dev/null
    echo "Started fresh container $CONTAINER (repo mounted at /repo)"
fi

# Serve /repo over HTTP for $PS_REPO_URL (pwsh 7 doesn't support file://).
if ! docker exec "$CONTAINER" curl -fsS -o /dev/null http://127.0.0.1:8000/ 2>/dev/null; then
    docker exec -d "$CONTAINER" python3 /serve.py
fi

# Attach: interactive shell by default, or run the given pwsh arguments
TTY_FLAGS=""
if [ -t 0 ] && [ -t 1 ]; then
    TTY_FLAGS="-it"
fi

if [ $# -eq 0 ]; then
    docker exec $TTY_FLAGS "$CONTAINER" pwsh
else
    docker exec $TTY_FLAGS "$CONTAINER" pwsh "$@"
fi
