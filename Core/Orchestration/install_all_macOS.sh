#!/bin/bash
# @doc
# @name: Full Installation (macOS)
# @description: Orchestrate the full installation of Miniforge and VS Code on macOS
# @category: Core
# @usage: bash Core/Orchestration/install_all_macOS.sh
# @requirements: macOS, curl, unzip
# @notes: Runs all installation steps in order: Miniforge, VS Code (with extensions and settings)
# @/doc

set -euo pipefail

PS_REPO_URL="${PS_REPO_URL:-https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main}"
export PS_REPO_URL

# Load the progress UI (defines the `progress` helper; the source guard in
#source <(curl -fsSL "$PS_REPO_URL/Utils/progress.sh")

echo "========================================="
echo "  DTU Python Support - Full Installation"
echo "========================================="
echo ""

# Step 1: Install Miniforge/Conda
#progress "Step 1/2: Miniforge" 10 \
bash <(curl -fsSL "$PS_REPO_URL/Core/Conda/install/install_macOS.sh")

# Step 2: Install VS Code (includes extensions and settings)
#progress "Step 2/2: VS Code" 5 \
bash <(curl -fsSL "$PS_REPO_URL/Core/VsCode/install/install_macOS.sh")

echo "========================================="
echo "  Installation complete!"
echo "  Restart your terminal to activate conda."
echo "========================================="
