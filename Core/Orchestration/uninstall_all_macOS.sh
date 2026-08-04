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

PS_REPO_URL="${PS_REPO_URL:-https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev}"
export PS_REPO_URL

echo "========================================="
echo "  DTU Python Support - Full Uninstall"
echo "========================================="
echo ""

# Step 1: Uninstall VS Code
echo "--- Step 1/2: VS Code ---"
bash <(curl -fsSL "$PS_REPO_URL/Utils/VsCode/uninstall_macOS.sh")
echo ""

# Step 2: Uninstall Conda
echo "--- Step 2/2: Conda ---"
bash <(curl -fsSL "$PS_REPO_URL/Utils/Conda/uninstall_macOS.sh")
echo ""

echo "========================================="
echo "  Uninstall complete!"
echo "========================================="
