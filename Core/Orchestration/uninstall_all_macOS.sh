#!/bin/bash
# @doc
# @name: Full Uninstall (macOS)
# @description: Orchestrate the full uninstall of Miniforge and VS Code on macOS
# @category: Core
# @usage: bash Core/Orchestration/uninstall_all_macOS.sh
# @requirements: macOS
# @notes: Runs all uninstall steps in order: VS Code, Conda
# @/doc

set -euo pipefail

PS_REPO_URL="${PS_REPO_URL:-https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main}"
export PS_REPO_URL

run_repo_script() {
    local relative_path="$1"
    if [[ "${PS_OFFLINE:-0}" == "1" ]]; then
        /bin/bash "${PS_BUNDLE_ROOT:?PS_BUNDLE_ROOT is required in offline mode}/$relative_path"
    else
        /bin/bash <(curl -fsSL "$PS_REPO_URL/$relative_path")
    fi
}

echo "========================================="
echo "  DTU Python Support - Full Uninstall"
echo "========================================="
echo ""

# Step 1: Uninstall VS Code
echo "--- Step 1/2: VS Code ---"
run_repo_script "Utils/VsCode/uninstall_macOS.sh"
echo ""

# Step 2: Uninstall Conda
echo "--- Step 2/2: Conda ---"
run_repo_script "Utils/Conda/uninstall_macOS.sh"
echo ""

echo "========================================="
echo "  Uninstall complete!"
echo "========================================="
