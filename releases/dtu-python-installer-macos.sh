#!/bin/bash
# DTU Python Support - macOS Installer Release
# Version: 1.0.0
# Double-click to install Python development environment for DTU students

# Set release configuration for local testing (configured for current fork/branch)
export REMOTE_PS="${REMOTE_PS:-philipnickel/pythonsupport-scripts}"
export BRANCH_PS="${BRANCH_PS:-MacOS_DEV}"
export DTU_INSTALLER_VERSION="1.0.0"

# DTU Python installer configuration
export PYTHON_VERSION_DTU="3.12"
export DTU_PACKAGES="dtumathtools pandas scipy statsmodels uncertainties"
export VSCODE_EXTENSIONS="ms-python.python ms-python.pylint ms-toolsai.jupyter tomoki1207.pdf"
export MINIFORGE_PATH="$HOME/miniforge3"
export MINIFORGE_BASE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX"

echo "🍎 DTU Python Support - macOS Installer"
echo "========================================"
echo "This will install Python and VS Code for DTU coursework"
echo "Repository: $REMOTE_PS"
echo "Branch: $BRANCH_PS"
echo "PIS_ENV: ${PIS_ENV:-not set}"
echo ""

# Export all variables so they're available to child processes
export REMOTE_PS
export BRANCH_PS  
export PIS_ENV
export PYTHON_VERSION_DTU
export DTU_PACKAGES
export VSCODE_EXTENSIONS
export MINIFORGE_PATH
export MINIFORGE_BASE_URL

# Function to check if we're running in CI
is_ci_mode() {
    [[ "${PIS_ENV:-}" == "CI" ]]
}

# Function to get sudo privileges once and cache them
get_sudo_privileges() {
    if is_ci_mode; then
        echo "Running in CI mode - sudo not needed for user installations"
        return 0
    fi
    
    echo "Requesting administrator privileges for installation..."
    
    # Use macOS native dialog to request sudo
    osascript -e 'tell app "System Events" to display dialog "DTU Python Support needs administrator privileges to install Python and VS Code.\n\nClick OK to continue with the installation." buttons {"Cancel", "OK"} default button "OK" with icon note' >/dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        echo "Installation cancelled by user."
        exit 1
    fi
    
    # Test sudo access
    if ! sudo -n true 2>/dev/null; then
        echo "Please enter your password when prompted..."
        sudo -v
        if [ $? -ne 0 ]; then
            echo "Failed to get administrator privileges. Installation cancelled."
            exit 1
        fi
    fi
    
    # Keep sudo privileges alive for the duration of the script
    while true; do
        sudo -n true
        sleep 50
        kill -0 "$$" || exit
    done 2>/dev/null &
    
    echo "Administrator privileges obtained."
}

# Get sudo privileges at the start
get_sudo_privileges

# Execute main installer with environment variables passed through
echo "Starting installation process..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/install.sh)"