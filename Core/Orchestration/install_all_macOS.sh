#!/bin/bash
# @doc
# @name: Install everything
# @description: Orchestrate the full installation of Miniforge and VS Code on macOS
# @category: Core
# @usage: curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Core/Orchestration/install_all_macOS.sh | bash
# @requirements: macOS, curl, unzip
# @notes: Runs all installation steps in order: Miniforge, VS Code (with extensions and settings)
# @/doc

set -euo pipefail

if [[ -n "${PS_OFFLINE+x}" ]]; then
    echo "PS_OFFLINE is no longer supported; use PS_ENV=offline." >&2
    exit 2
fi

load_environment() {
    local env_source
    if [[ "${PS_ENV:-}" == "offline" || ( -z "${PS_ENV:-}" && -n "${PS_BUNDLE_ROOT:-}" ) ]]; then
        env_source="${PS_BUNDLE_ROOT:?PS_BUNDLE_ROOT is required for offline initialization}/Core/env.sh"
    elif [[ "${PS_ENV:-}" == "main" ]]; then
        env_source="https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Core/env.sh"
    elif [[ -n "${PS_REPO_URL:-}" ]]; then
        env_source="${PS_REPO_URL%/}/Core/env.sh"
    else
        local repo_user="${PS_REPO_USER:-dtudk}"
        local branch="${PS_BRANCH:-main}"
        env_source="https://raw.githubusercontent.com/$repo_user/pythonsupport-scripts/$branch/Core/env.sh"
    fi

    if [[ "$env_source" == http://* || "$env_source" == https://* || "$env_source" == file://* ]]; then
        local env_content
        env_content="$(curl -fsSL "$env_source")"
        # shellcheck source=/dev/stdin
        source /dev/stdin <<< "$env_content"
    else
        # shellcheck source=/dev/null
        source "$env_source"
    fi
}

load_environment

echo "========================================="
echo "  DTU Python Support - Full Installation"
echo "========================================="
echo ""

# Step 1: Install Miniforge/Conda
run_repo_script "Core/Conda/install/install_macOS.sh"

# Step 2: Install VS Code (includes extensions and settings)
run_repo_script "Core/VsCode/install/install_macOS.sh"
run_repo_script "Core/VsCode/config/settings_macOS.sh"
if ! run_repo_script "Core/VsCode/config/extensions_macOS.sh"; then
    echo "  [WARNING] VS Code extensions were not installed." >&2
    echo "  Connect to the internet and run the VS Code setup again." >&2
fi

echo "========================================="
echo "  Installation complete!"
echo "  Restart your terminal to activate conda."
echo "========================================="
