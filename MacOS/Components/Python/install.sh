#!/bin/bash
# Python Component Installer - Clean Implementation
# Installs Miniconda for Python development
# Usage: /bin/bash -c "$(curl -fsSL .../install_clean.sh)"
# Exit codes: 0=success, 1=failure, 10=already installed

set -euo pipefail  # Strict error handling

# Load minimal utilities
REMOTE_PS="${REMOTE_PS:-dtudk/pythonsupport-scripts}"
BRANCH_PS="${BRANCH_PS:-main}"
BASE_URL="https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared"

# Source utilities
eval "$(curl -fsSL "$BASE_URL/minimal_utils.sh")"

# Component configuration
readonly COMPONENT_NAME="Python/Miniconda"
readonly ANALYTICS_PREFIX="python"

install_homebrew_if_missing() {
    if ! command -v brew >/dev/null 2>&1; then
        output "info" "Installing Homebrew..." "$COMPONENT_NAME"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

install_miniconda() {
    # Check if already installed
    if is_installed "conda" "conda --version"; then
        local version=$(conda --version 2>/dev/null || echo "unknown version")
        output "skip" "$version" "$COMPONENT_NAME"
        exit_with_status "$EXIT_ALREADY_INSTALLED" "$ANALYTICS_PREFIX" "already_installed"
    fi
    
    output "info" "Installing..." "$COMPONENT_NAME"
    
    # Ensure Homebrew is available
    install_homebrew_if_missing
    
    # Install Miniconda
    if brew install --cask miniconda; then
        # Initialize conda
        local conda_base="/opt/homebrew/Caskroom/miniconda/base"
        [[ ! -d "$conda_base" ]] && conda_base="/usr/local/Caskroom/miniconda/base"
        
        if [[ -f "$conda_base/bin/conda" ]]; then
            eval "$($conda_base/bin/conda shell.bash hook)"
            conda init bash zsh >/dev/null 2>&1 || true
            
            # Configure conda channels
            conda config --remove channels defaults 2>/dev/null || true
            conda config --add channels conda-forge 2>/dev/null || true
            conda config --set channel_priority flexible 2>/dev/null || true
            conda config --set anaconda_anon_usage off 2>/dev/null || true
            
            output "success" "installed successfully" "$COMPONENT_NAME"
            exit_with_status "$EXIT_SUCCESS" "$ANALYTICS_PREFIX" "install_success"
        else
            output "error" "installation completed but conda not accessible" "$COMPONENT_NAME"
            exit_with_status "$EXIT_FAILURE" "$ANALYTICS_PREFIX" "install_failed"
        fi
    else
        output "error" "installation failed" "$COMPONENT_NAME" 
        exit_with_status "$EXIT_FAILURE" "$ANALYTICS_PREFIX" "install_failed"
    fi
}

# Main execution
main() {
    install_miniconda
}

# Execute if run directly (not sourced)
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    main
fi