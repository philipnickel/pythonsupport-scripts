#!/bin/bash
# @doc
# @name: DTU Python Support - macOS Installer
# @description: Simple entry point for DTU first year Python environment setup
# @category: Main
# @usage: ./install.sh
# @requirements: macOS system, internet connection
# @notes: Complete setup with pre/post verification and diagnostics
# @/doc

echo "DTU Python Support - macOS Installation"
echo "======================================="
echo ""
echo "This will install:"
echo "• Python 3.11 with DTU mathematical tools"
echo "• Visual Studio Code with Python extension"
echo "• Complete diagnostic and verification system"
echo ""

# Detect CI/headless environment
CI_MODE=false
if [ "$CI" = "true" ] || [ "$GITHUB_ACTIONS" = "true" ] || [ -n "$BUILD_ID" ] || [ -n "$JENKINS_URL" ] || [ ! -t 0 ]; then
    CI_MODE=true
    echo "Detected CI/automated environment - running in non-interactive mode"
    echo ""
else
    # Interactive mode - ask for system password confirmation using macOS native dialog
    echo "This installation requires administrator privileges."
    echo "You will be prompted to enter your system password."
    echo ""

    # Use osascript to show native macOS password dialog
    if ! osascript -e 'do shell script "echo Authentication successful" with administrator privileges' >/dev/null 2>&1; then
        echo "Installation cancelled - administrator authentication required."
        exit 1
    fi

    echo "Authentication successful. Starting installation..."
fi

# Set default repository and branch for direct oneliner usage
[ -z "$REMOTE_PS" ] && REMOTE_PS="philipnickel/pythonsupport-scripts"
[ -z "$BRANCH_PS" ] && BRANCH_PS="Miniforge"

# Load simple utilities directly
if ! eval "$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared/common.sh")"; then
    echo "ERROR: Failed to load utilities from remote repository"
    exit 1
fi

# Set up installation logging
INSTALL_LOG="/tmp/dtu_install_$(date +%Y%m%d_%H%M%S).log"

log_info "DTU First Year Students - Complete Setup"
log_info "========================================"
log_info "Installation log: $INSTALL_LOG"

# === PHASE 1: PRE-INSTALLATION CHECK ===
log_info "Phase 1: Pre-Installation System Check"
log_info "======================================="

piwik_log 'pre_install_check' /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Core/pre_install.sh)"
log_success "Pre-installation check completed"

# === PHASE 2: MAIN INSTALLATION ===
log_info "Phase 2: Main Installation Process"
log_info "=================================="

# Install Python with Miniforge
log_info "Installing Python 3.11 with Miniforge..."
piwik_log 'python_install' /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Python/install.sh)"
log_success "Python installation completed"

# Setup first year Python environment and packages
log_info "Setting up first year Python environment..."
piwik_log 'python_first_year_setup' /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Python/first_year_setup.sh)"
log_success "Python environment setup completed"

# Install Visual Studio Code
log_info "Installing Visual Studio Code..."
piwik_log 'vscode_install' /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/VSC/install.sh)"
log_success "VS Code installation completed"

log_info "Main installation phase completed"

# === PHASE 3: POST-INSTALLATION VERIFICATION ===
log_info "Phase 3: Post-Installation Verification"
log_info "========================================"

# Export the install log for post-install verification
export INSTALL_LOG

if piwik_log 'post_install_verification' /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Core/post_install.sh)"; then
    log_success "Post-installation verification completed successfully"
    echo ""
    echo "🎉 DTU First Year Setup Complete!"
    echo "================================="
    echo "Your system is now ready with:"
    echo "• Python 3.11 with DTU packages"
    echo "• Visual Studio Code with Python extension"
    echo "• Comprehensive diagnostics report"
    echo ""
    echo "Next steps:"
    echo "• Open VS Code: type 'code' in Terminal"
    echo "• Start coding with Python and dtumathtools"
    echo "• Check diagnostic report for details"
    echo ""
    echo "Need help? Visit: https://pythonsupport.dtu.dk"
    echo "Questions? Email: pythonsupport@dtu.dk"
    exit 0
else
    log_warning "Post-installation verification detected issues"
    echo ""
    echo "Installation completed but with some issues detected."
    echo "A diagnostic report has been generated for troubleshooting."
    echo ""
    echo "For support:"
    echo "• Visit: https://pythonsupport.dtu.dk/install/macos/automated-error.html"
    echo "• Email: pythonsupport@dtu.dk"
    echo "• Include the diagnostic report when contacting support"
    exit 1
fi
