#!/bin/bash
# @doc
# @name: Install macOS Launcher
# @description: Interactive launcher to install or uninstall Miniforge and VS Code on macOS
# @category: Launchers
# @usage: bash "Install macOS.command"
# @requirements: macOS
# @/doc

set -euo pipefail

bundle_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PS_BUNDLE_ROOT="$bundle_root"
export PS_OFFLINE=1

# Auto-detect architecture
case "$(uname -m)" in
    arm64) export PS_BUNDLE_PLATFORM="macos-arm64" ;;
    x86_64) export PS_BUNDLE_PLATFORM="macos-x86_64" ;;
    *) echo "Unsupported macOS architecture: $(uname -m)" >&2; exit 1 ;;
esac

run_action() {
    local action="$1"
    case "$action" in
        1)
            echo ""
            echo ">>> Running Full Installation..."
            /bin/bash "$bundle_root/Core/Orchestration/install_all_macOS.sh"
            ;;
        2)
            echo ""
            echo ">>> Installing Miniforge..."
            /bin/bash "$bundle_root/Core/Conda/install/install_macOS.sh"
            ;;
        3)
            echo ""
            echo ">>> Installing VS Code (with extensions & settings)..."
            /bin/bash "$bundle_root/Core/VsCode/install/install_macOS.sh"
            ;;
        4)
            echo ""
            echo ">>> Running Full Uninstall..."
            /bin/bash "$bundle_root/Core/Orchestration/uninstall_all_macOS.sh"
            ;;
        5)
            echo ""
            echo ">>> Uninstalling Miniforge..."
            /bin/bash "$bundle_root/Utils/Conda/uninstall_macOS.sh"
            ;;
        6)
            echo ""
            echo ">>> Uninstalling VS Code..."
            /bin/bash "$bundle_root/Utils/VsCode/uninstall_macOS.sh"
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
    echo "  [1] Full Installation (Miniforge + VS Code) [Default]"
    echo "  [2] Install Miniforge only"
    echo "  [3] Install VS Code only (with extensions & settings)"
    echo "  ---------------------------------------------------"
    echo "  [4] Full Uninstall (Miniforge + VS Code)"
    echo "  [5] Uninstall Miniforge only"
    echo "  [6] Uninstall VS Code only"
    echo "  ---------------------------------------------------"
    echo "  [q] Quit"
    echo "====================================================="
    read -r -p "Enter choice [1-6, or q] (Default: 1): " choice
    choice="${choice:-1}"

    if run_action "$choice"; then
        echo ""
        read -r -p "Press Enter to return to menu, or 'q' to quit: " after_choice
        if [[ "$after_choice" =~ ^[qQ]$ ]]; then
            break
        fi
    fi
done
