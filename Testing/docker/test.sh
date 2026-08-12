#!/usr/bin/env bash
# Rebuild the PowerShell test image, reset its container, and run all Windows tests.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE="ps-windows-test"
CONTAINER="ps-windows-test"

docker build -t "$IMAGE" -f "$REPO_ROOT/Testing/docker/Dockerfile.windows" "$REPO_ROOT/Testing/docker"
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true

exec "$REPO_ROOT/Testing/docker/run.sh" -NoProfile -File ./Testing/windows/run_tests.ps1
