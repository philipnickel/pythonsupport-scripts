#!/bin/bash
# Python First Year Setup - Clean Implementation
# Sets up Python 3.11 environment with required packages
# Usage: /bin/bash -c "$(curl -fsSL .../first_year_setup_clean.sh)"
# Exit codes: 0=success, 1=failure, 10=already configured

set -euo pipefail

# Load minimal utilities  
REMOTE_PS="${REMOTE_PS:-dtudk/pythonsupport-scripts}"
BRANCH_PS="${BRANCH_PS:-main}"
BASE_URL="https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared"

eval "$(curl -fsSL "$BASE_URL/minimal_utils.sh")"

# Configuration
readonly COMPONENT_NAME="Python Environment"
readonly ANALYTICS_PREFIX="python_setup"
readonly PYTHON_VERSION="${PYTHON_VERSION_PS:-3.11}"
readonly REQUIRED_PACKAGES=("dtumathtools" "pandas" "scipy" "statsmodels" "uncertainties")

activate_conda() {
    # Load shell profiles to get conda environment
    [[ -f ~/.bashrc ]] && source ~/.bashrc || true
    [[ -f ~/.bash_profile ]] && source ~/.bash_profile || true
    [[ -f ~/.zshrc ]] && source ~/.zshrc 2>/dev/null || true
    
    # Try conda activation methods
    if command -v conda >/dev/null 2>&1; then
        eval "$(conda shell.bash hook)" 2>/dev/null || true
        conda activate base 2>/dev/null || true
    fi
}

check_python_environment() {
    activate_conda
    
    # Check if correct Python version is installed
    if command -v python3 >/dev/null 2>&1; then
        local current_version
        current_version=$(python3 --version 2>/dev/null | cut -d' ' -f2)
        
        if [[ "$current_version" =~ ^${PYTHON_VERSION} ]]; then
            # Check if required packages are installed
            local missing_packages=()
            for package in "${REQUIRED_PACKAGES[@]}"; do
                if ! python3 -c "import $package" 2>/dev/null; then
                    missing_packages+=("$package")
                fi
            done
            
            if [[ ${#missing_packages[@]} -eq 0 ]]; then
                output "skip" "Python $current_version with all packages" "$COMPONENT_NAME"
                exit_with_status "$EXIT_ALREADY_INSTALLED" "$ANALYTICS_PREFIX" "already_configured"
            fi
        fi
    fi
    
    return 1  # Not properly configured
}

install_conda_if_missing() {
    if ! command -v conda >/dev/null 2>&1; then
        output "info" "Installing Miniconda first..." "$COMPONENT_NAME"
        env PIS_INSTALL_METHOD="$INSTALL_METHOD" \
            /bin/bash -c "$(curl -fsSL "$BASE_URL/../Python/install_clean.sh")"
        
        # Re-activate after installation
        activate_conda
    fi
}

setup_python_environment() {
    # Check if already configured
    if check_python_environment; then
        return 0
    fi
    
    output "info" "Configuring Python $PYTHON_VERSION environment..." "$COMPONENT_NAME"
    
    # Ensure conda is available
    install_conda_if_missing
    activate_conda
    
    # Install Python version
    if conda install --strict-channel-priority "python=$PYTHON_VERSION" -y; then
        output "info" "Python $PYTHON_VERSION installed" "$COMPONENT_NAME"
    else
        output "error" "failed to install Python $PYTHON_VERSION" "$COMPONENT_NAME"
        exit_with_status "$EXIT_FAILURE" "$ANALYTICS_PREFIX" "python_install_failed"
    fi
    
    # Install required packages
    local package_list="${REQUIRED_PACKAGES[*]}"
    if conda install $package_list -y; then
        output "success" "Python $PYTHON_VERSION with all packages configured" "$COMPONENT_NAME"
        exit_with_status "$EXIT_SUCCESS" "$ANALYTICS_PREFIX" "setup_success"
    else
        output "error" "failed to install required packages" "$COMPONENT_NAME"
        exit_with_status "$EXIT_FAILURE" "$ANALYTICS_PREFIX" "packages_install_failed" 
    fi
}

# Main execution
main() {
    setup_python_environment
}

if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    main
fi