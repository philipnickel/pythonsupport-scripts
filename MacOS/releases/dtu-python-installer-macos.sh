#!/bin/bash
# DTU Python Support - macOS Installer Release
# Version: 1.0.0
# Double-click to install Python development environment for DTU students
# 
# Usage:
#   GUI Mode (double-click): Uses native macOS authentication dialogs
#   CLI Mode (one-liner): DTU_CLI_MODE=true /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/...)"
#   CLI Mode (downloaded): bash dtu-python-installer-macos.sh --cli

# Parse command line arguments for CLI mode or check environment variable
CLI_MODE=false
if [[ "$1" == "--cli" ]] || [[ "${DTU_CLI_MODE:-}" == "true" ]]; then
    CLI_MODE=true
    shift
fi

# Set release configuration for local testing (configured for current fork/branch)
export REMOTE_PS="${REMOTE_PS:-philipnickel/pythonsupport-scripts}"
export BRANCH_PS="${BRANCH_PS:-main}"
export DTU_INSTALLER_VERSION="1.0.0"

# DTU Python installer configuration
export PYTHON_VERSION_DTU="3.12"
export DTU_PACKAGES="dtumathtools pandas scipy statsmodels uncertainties"
export VSCODE_EXTENSIONS="ms-python.python ms-toolsai.jupyter tomoki1207.pdf"
export MINIFORGE_PATH="$HOME/miniforge3"
export MINIFORGE_BASE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX"

# Set up logging
INSTALL_LOG="/tmp/dtu_install_$(date +%Y%m%d_%H%M%S).log"

echo "🍎 DTU Python Support - macOS Installer"
echo "========================================"
echo "This will install Python and VS Code for DTU coursework"
echo "Repository: $REMOTE_PS"
echo "Branch: $BRANCH_PS"
echo "Mode: $([ "$CLI_MODE" = true ] && echo "CLI" || echo "GUI")"
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
export INSTALL_LOG
export CLI_MODE

# Initialize log
echo "=== DTU Python Support Installation Log ===" > "$INSTALL_LOG"
echo "Started: $(date)" >> "$INSTALL_LOG"
echo "Repository: $REMOTE_PS" >> "$INSTALL_LOG"
echo "Branch: $BRANCH_PS" >> "$INSTALL_LOG"
echo "Mode: $([ "$CLI_MODE" = true ] && echo "CLI" || echo "GUI")" >> "$INSTALL_LOG"
echo "" >> "$INSTALL_LOG"

# Function to log all output
log_and_display() {
    while IFS= read -r line; do
        echo "$line"
        echo "$line" >> "$INSTALL_LOG"
    done
}

# Function to check if we're running in CI
is_ci_mode() {
    [[ "${PIS_ENV:-}" == "CI" ]]
}

# Function to download and execute script (preserves sudo cache)
download_and_execute() {
    local url="$1"
    local description="$2"
    
    echo "$description..."
    
    # Execute in current shell to preserve sudo credential cache
    curl -fsSL "$url" | bash
}

# Function to get authentication privileges  
get_authentication() {
    if is_ci_mode; then
        echo "Running in CI mode - no authentication needed"
        return 0
    fi
    
    if [ "$CLI_MODE" = true ]; then
        echo "CLI Mode: Using terminal-based authentication"
        echo "Administrator privileges may be required for some operations."
        return 0
    else
        echo "GUI Mode: Using native macOS authentication dialogs"
        echo "You will be prompted for administrator privileges when needed."
        return 0
    fi
}

# Get authentication info
get_authentication

echo "Starting installation process..." | tee -a "$INSTALL_LOG"

# === PHASE 1: PRE-INSTALLATION CHECK ===
{
echo "Phase 1: Pre-Installation System Check"
echo "======================================="
download_and_execute "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Core/pre_install.sh" "Running pre-installation checks"
} 2>&1 | log_and_display

# Load pre-installation flags
if [ -f /tmp/dtu_pre_install_flags.env ]; then
    source /tmp/dtu_pre_install_flags.env
fi

# Echo findings
echo ""
echo "Phase 1 Findings:"
echo "-----------------"
if [ "$SKIP_VSCODE_INSTALL" = true ]; then
    echo "• VS Code: Already installed - will skip"
else
    echo "• VS Code: Not found - will install"
fi
echo ""

# === PHASE 2: MAIN INSTALLATION ===
{
echo "Phase 2: Main Installation Process"
echo "=================================="

# Install Python with Miniforge
download_and_execute "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Python/install.sh" "Installing Python with Miniforge"

# Setup Python environment and packages
download_and_execute "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Python/first_year_setup.sh" "Setting up Python environment and packages"

# Install Visual Studio Code and extensions
if [ "$SKIP_VSCODE_INSTALL" = true ]; then
    echo "VS Code already installed - ensuring extensions are installed..."
else
    echo "Installing Visual Studio Code..."
fi
download_and_execute "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/VSC/install.sh" "Installing VS Code and extensions"
} 2>&1 | log_and_display

# === PHASE 3: POST-INSTALLATION VERIFICATION ===
{
echo "Phase 3: Post-Installation Verification"
echo "========================================"

download_and_execute "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Core/post_install.sh" "Running post-installation verification"

echo ""
echo "DTU Python Support Installation Complete!"
echo "========================================"
echo "Installation log: $INSTALL_LOG"
echo "Next steps:"
echo "• See the Installation HTML report for details"
echo "Need help? Visit: https://pythonsupport.dtu.dk"
} 2>&1 | log_and_display