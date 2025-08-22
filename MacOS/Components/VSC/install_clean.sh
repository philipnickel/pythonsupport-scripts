#!/bin/bash
# VS Code Component Installer - Clean Implementation  
# Installs Visual Studio Code
# Exit codes: 0=success, 1=failure, 10=already installed

set -euo pipefail

# Load minimal utilities
REMOTE_PS="${REMOTE_PS:-dtudk/pythonsupport-scripts}"
BRANCH_PS="${BRANCH_PS:-main}"
BASE_URL="https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared"

eval "$(curl -fsSL "$BASE_URL/minimal_utils.sh")"

# Configuration
readonly COMPONENT_NAME="VS Code"
readonly ANALYTICS_PREFIX="vscode"

install_homebrew_if_missing() {
    if ! command -v brew >/dev/null 2>&1; then
        output "info" "Installing Homebrew..." "$COMPONENT_NAME"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

install_vscode() {
    # Check if already installed
    if is_installed "code" "code --version"; then
        local version=$(code --version 2>/dev/null | head -1 || echo "unknown version")
        output "skip" "$version" "$COMPONENT_NAME"
        exit_with_status "$EXIT_ALREADY_INSTALLED" "$ANALYTICS_PREFIX" "already_installed"
    fi
    
    output "info" "Installing..." "$COMPONENT_NAME"
    
    # Ensure Homebrew is available
    install_homebrew_if_missing
    
    # Install VS Code
    if brew install --cask visual-studio-code; then
        # Verify installation
        if command -v code >/dev/null 2>&1; then
            output "success" "installed successfully" "$COMPONENT_NAME"
            exit_with_status "$EXIT_SUCCESS" "$ANALYTICS_PREFIX" "install_success"
        else
            output "error" "installation completed but 'code' command not available" "$COMPONENT_NAME"
            exit_with_status "$EXIT_FAILURE" "$ANALYTICS_PREFIX" "install_failed"
        fi
    else
        output "error" "installation failed" "$COMPONENT_NAME"
        exit_with_status "$EXIT_FAILURE" "$ANALYTICS_PREFIX" "install_failed"
    fi
}

# Main execution
main() {
    install_vscode
}

if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    main
fi