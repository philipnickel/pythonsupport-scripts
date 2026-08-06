#!/usr/bin/env bash
set -euo pipefail
IFS=$' \t\n'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT_DIR/tools/build.sh"

echo "Running integration dry-run"
"$ROOT_DIR/dist/dtu-python-installer-macos.sh" --dry-run | tee /tmp/macos_next_smoke.log

grep -q "Execution plan:" /tmp/macos_next_smoke.log
grep -q "Dry-run complete" /tmp/macos_next_smoke.log

echo "Smoke test passed"

# Also test with VS Code flag (still dry-run)
"$ROOT_DIR/dist/dtu-python-installer-macos.sh" --dry-run --with-vscode | tee /tmp/macos_next_smoke_vscode.log
grep -q "Install VS Code" /tmp/macos_next_smoke_vscode.log
echo "Smoke with VS Code flag passed"
