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

run_repo_script() {
    local relative_path="$1"
    if [[ "${PS_OFFLINE:-0}" == "1" ]]; then
        /bin/bash "${PS_BUNDLE_ROOT:?PS_BUNDLE_ROOT is required in offline mode}/$relative_path"
    else
        /bin/bash <(curl -fsSL "$PS_REPO_URL/$relative_path")
    fi
}

if [[ "${PS_OFFLINE:-0}" == "1" ]]; then
    case "$(uname -m)" in
        arm64) export PS_BUNDLE_PLATFORM="macos-arm64" ;;
        x86_64) export PS_BUNDLE_PLATFORM="macos-x86_64" ;;
        *) echo "Unsupported macOS architecture: $(uname -m)" >&2; exit 1 ;;
    esac
fi

echo "========================================="
echo "  DTU Python Support - Full Installation"
echo "========================================="
echo ""

# Step 1: Install Miniforge/Conda
run_repo_script "Core/Conda/install/install_macOS.sh"

# Step 2: Install VS Code (includes extensions and settings)
run_repo_script "Core/VsCode/install/install_macOS.sh"

echo "========================================="
echo "  Installation complete!"
echo "  Restart your terminal to activate conda."
echo "========================================="
