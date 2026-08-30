#!/bin/bash
# @doc
# @name: Install macOS Launcher
# @description: Interactive launcher to install or uninstall Miniforge and VS Code on macOS
# @category: Launchers
# @usage: bash "Install macOS.command"
# @requirements: macOS
# @/doc

set -euo pipefail

if [[ -n "${PS_OFFLINE+x}" ]]; then
    echo "PS_OFFLINE is no longer supported; use PS_ENV=offline." >&2
    exit 2
fi

bundle_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "${PS_ENV:-}" && -z "${PS_BUNDLE_ROOT:-}" && -z "${PS_REPO_URL:-}" && -z "${PS_REPO_USER:-}" && -z "${PS_BRANCH:-}" && -z "${PS_FORGE_URL:-}" && -z "${PS_VSCODE_URL:-}" ]]; then
    export PS_ENV="offline"
    export PS_BUNDLE_ROOT="$bundle_root"
elif [[ "${PS_ENV:-}" == "offline" && -z "${PS_BUNDLE_ROOT:-}" ]]; then
    export PS_BUNDLE_ROOT="$bundle_root"
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

run_action() {
    local action="$1"
    case "$action" in
        1|install-all)
            echo ""
            echo ">>> Running Full Installation..."
            run_repo_script "Core/Conda/install/install_macOS.sh"
            run_repo_script "Core/VsCode/install/install_macOS.sh"
            run_repo_script "Core/VsCode/config/settings_macOS.sh"
            if ! run_repo_script "Core/VsCode/config/extensions_macOS.sh"; then
                echo "  [WARNING] VS Code extensions were not installed." >&2
                echo "  Connect to the internet and run the VS Code setup again." >&2
            fi
            ;;
        2|install-conda)
            echo ""
            echo ">>> Installing Miniforge..."
            run_repo_script "Core/Conda/install/install_macOS.sh"
            ;;
        3|install-vscode)
            echo ""
            echo ">>> Installing VS Code (with extensions & settings)..."
            run_repo_script "Core/VsCode/install/install_macOS.sh"
            run_repo_script "Core/VsCode/config/settings_macOS.sh"
            run_repo_script "Core/VsCode/config/extensions_macOS.sh"
            ;;
        4|uninstall-all)
            echo ""
            echo ">>> Running Full Uninstall..."
            run_repo_script "Utils/VsCode/uninstall_macOS.sh"
            run_repo_script "Utils/Conda/uninstall_macOS.sh"
            ;;
        5|uninstall-conda)
            echo ""
            echo ">>> Uninstalling Miniforge..."
            run_repo_script "Utils/Conda/uninstall_macOS.sh"
            ;;
        6|uninstall-vscode)
            echo ""
            echo ">>> Uninstalling VS Code..."
            run_repo_script "Utils/VsCode/uninstall_macOS.sh"
            ;;
        q|Q)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid choice: $action"
            return 1
            ;;
    esac
}

# If an action argument is provided, run directly and exit
if [[ $# -gt 0 ]]; then
    run_action "$1"
    exit $?
fi

# If stdin is not a terminal, run default (Full Installation)
if [[ ! -t 0 ]]; then
    run_action 1
    exit $?
fi

while true; do
    echo ""
    echo "====================================================="
    echo "            DTU Python Support (macOS)"
    echo "====================================================="
    echo "  [1] Full Installation (install-all) [Default]"
    echo "  [2] Install Miniforge only (install-conda)"
    echo "  [3] Install VS Code only (install-vscode)"
    echo "  ---------------------------------------------------"
    echo "  [4] Full Uninstall (uninstall-all)"
    echo "  [5] Uninstall Miniforge only (uninstall-conda)"
    echo "  [6] Uninstall VS Code only (uninstall-vscode)"
    echo "  ---------------------------------------------------"
    echo "  [q] Quit"
    echo "====================================================="
    read -r -p "Enter choice [1-6, or q] (Default: 1): " choice
    choice="${choice:-1}"

    if run_action "$choice"; then
        echo ""
        echo "====================================================="
        echo " [OK] Completed successfully! Closing window..."
        echo "====================================================="
        osascript -e 'tell application "Terminal" to close (every window whose name contains "Install macOS")' 2>/dev/null || \
        osascript -e 'tell application "Terminal" to close front window' 2>/dev/null || true
        exit 0
    fi
done
