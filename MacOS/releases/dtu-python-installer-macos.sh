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
export REMOTE_PS="${REMOTE_PS:-dtudk/pythonsupport-scripts}"
export BRANCH_PS="${BRANCH_PS:-main}"
export DTU_INSTALLER_VERSION="1.0.0"

# DTU Python installer configuration
export PYTHON_VERSION_DTU="3.12"
export DTU_PACKAGES="dtumathtools pandas scipy statsmodels uncertainties"
# VSCODE_EXTENSIONS removed - extensions now hardcoded in VSC install script
export MINIFORGE_PATH="$HOME/miniforge3"
export MINIFORGE_BASE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX"

# Set up logging
INSTALL_LOG="/tmp/dtu_install_$(date +%Y%m%d_%H%M%S).log"

# Load Piwik utility for analytics
echo "Loading analytics utility..."
if curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared/piwik_utility.sh" -o /tmp/piwik_utility.sh 2>/dev/null && source /tmp/piwik_utility.sh 2>/dev/null; then
    echo "Analytics loaded successfully"
    ANALYTICS_ENABLED=true
else
    # Define dummy piwik_log function if loading fails
    piwik_log() { :; }  # No-op function
    echo "Analytics disabled (could not load utility)"
    ANALYTICS_ENABLED=false
fi

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
# VSCODE_EXTENSIONS export removed
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

# Function to download and execute script (preserves sudo cache and environment variables)
download_and_execute() {
    local url="$1"
    local description="$2"
    
    echo "$description..."
    
    # Execute with environment variables passed to preserve sudo credential cache and ensure child scripts have access to variables
    # Use a temporary file to capture exit code
    local temp_script="/tmp/dtu_temp_script_$$.sh"
    curl -fsSL "$url" > "$temp_script"
    local curl_exit_code=$?
    
    if [ $curl_exit_code -eq 0 ]; then
        REMOTE_PS="$REMOTE_PS" BRANCH_PS="$BRANCH_PS" PIS_ENV="$PIS_ENV" PYTHON_VERSION_DTU="$PYTHON_VERSION_DTU" DTU_PACKAGES="$DTU_PACKAGES" MINIFORGE_PATH="$MINIFORGE_PATH" MINIFORGE_BASE_URL="$MINIFORGE_BASE_URL" INSTALL_LOG="$INSTALL_LOG" CLI_MODE="$CLI_MODE" bash "$temp_script"
        local script_exit_code=$?
        rm -f "$temp_script"
        
        if [ $script_exit_code -ne 0 ]; then
            echo "ERROR: $description failed with exit code $script_exit_code"
            echo "Installation aborted."
            exit $script_exit_code
        fi
    else
        echo "ERROR: Failed to download script from $url"
        echo "Installation aborted."
        exit 1
    fi
}

# Function to show terms and conditions acceptance dialog
show_terms_acceptance() {
    if is_ci_mode; then
        echo "Running in CI mode - accepting terms automatically"
        return 0
    fi
    
    if [ "$CLI_MODE" = true ]; then
        echo ""
        echo "=== Terms and Conditions ==="
        echo ""
        echo "By proceeding with this installation, you agree to the following terms:"
        echo ""
        echo "1. This installer will download and install:"
        echo "   • Miniforge (Python environment manager): https://github.com/conda-forge/miniforge"
        echo "   • Visual Studio Code: https://code.visualstudio.com/"
        echo ""
        echo "2. The installer will:"
        echo "   • Install Python 3.12 and required packages for DTU coursework"
        echo "   • Configure your system for Python development"
        echo "   • Install VS Code with Python extensions"
        echo ""
        echo "3. System Requirements:"
        echo "   • macOS 10.15 or later"
        echo "   • Administrator privileges required for installation"
        echo ""
        echo "Do you accept these terms and conditions? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled by user."
            exit 0
        fi
        echo "Terms accepted. Proceeding with installation..."
    else
        # GUI mode - use osascript for native dialog with checkbox
        local response
        response=$(osascript -e 'tell app "System Events" to display dialog "DTU Python Support - Terms and Conditions\n\nBy proceeding with this installation, you agree to the following terms:\n\n1. This installer will download and install:\n   • Miniforge (Python environment manager): https://github.com/conda-forge/miniforge\n   • Visual Studio Code: https://code.visualstudio.com/\n\n2. The installer will:\n   • Install Python 3.12 and required packages for DTU coursework\n   • Configure your system for Python development\n   • Install VS Code with Python extensions\n\n3. System Requirements:\n   • macOS 10.15 or later\n   • Administrator privileges required for installation\n\nDo you accept these terms and conditions?" buttons {"Cancel", "Accept and Continue"} default button "Accept and Continue" with icon note')
        
        # Check if user cancelled or closed the dialog
        if [[ $? -ne 0 ]] || [[ -z "$response" ]] || [[ "$response" == *"Cancel"* ]]; then
            echo "Installation cancelled by user."
            exit 0
        fi
        

        echo "Terms accepted. Proceeding with installation..."
    fi
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

# Show terms and conditions acceptance
show_terms_acceptance

# Get authentication info
get_authentication

echo "Starting installation process..." | tee -a "$INSTALL_LOG"

# === PHASE 1: PRE-INSTALLATION CHECK ===
echo "Phase 1: Pre-Installation System Check"
echo "======================================="
download_and_execute "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Core/pre_install.sh" "Running pre-installation checks"
phase1_exit_code=$?

# Check if Phase 1 failed
if [ $phase1_exit_code -ne 0 ]; then
    echo "Phase 1 failed with exit code $phase1_exit_code"
    echo "Installation aborted."
    exit $phase1_exit_code
fi

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