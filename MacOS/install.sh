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

# Parse command line arguments and environment variables
VERBOSE_MODE=false

# Check environment variable first
[ "$PIS_VERBOSE" = "true" ] && VERBOSE_MODE=true

# Then parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE_MODE=true
            shift
            ;;
        --help|-h)
            echo "DTU Python Support - macOS Installation"
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --verbose, -v    Show detailed installation output"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  PIS_VERBOSE=true  Enable verbose mode"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Detect CI/headless environment and set output mode
CI_MODE=false
QUIET_MODE=true

if [ "$CI" = "true" ] || [ "$GITHUB_ACTIONS" = "true" ] || [ -n "$BUILD_ID" ] || [ -n "$JENKINS_URL" ] || [ ! -t 0 ]; then
    CI_MODE=true
    QUIET_MODE=false  # CI always runs in verbose mode
    echo "Detected CI/automated environment - running in verbose mode"
    echo ""
elif [ "$VERBOSE_MODE" = "true" ]; then
    QUIET_MODE=false  # User requested verbose mode
    echo "Running in verbose mode (--verbose flag detected)"
    echo ""
else
    # Interactive mode - enable quiet mode for clean user experience
    QUIET_MODE=true
    
    echo "This installation requires administrator privileges."
    echo "You will be prompted to enter your system password."
    echo ""

    # Use osascript to show native macOS password dialog
    if ! osascript -e 'do shell script "echo Authentication successful" with administrator privileges' >/dev/null 2>&1; then
        echo "Installation cancelled - administrator authentication required."
        exit 1
    fi

    echo "Authentication successful. Starting installation..."
    echo ""
    echo "Installation progress will be shown below."
    echo "Detailed logs are being written to: /tmp/dtu_install_$(date +%Y%m%d_%H%M%S).log"
    echo ""
    echo "For verbose output, run: $0 --verbose"
    echo ""
fi

# Export modes for child scripts
export CI_MODE
export QUIET_MODE
export VERBOSE_MODE

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
export INSTALL_LOG

# Initialize log file
echo "=== DTU Python Support Installation Log ===" > "$INSTALL_LOG"
echo "Started: $(date)" >> "$INSTALL_LOG"
echo "Mode: CI_MODE=$CI_MODE, QUIET_MODE=$QUIET_MODE" >> "$INSTALL_LOG"
echo "" >> "$INSTALL_LOG"

log_info "DTU First Year Students - Complete Setup"
log_info "========================================"
log_info "Installation log: $INSTALL_LOG"

# === PHASE 1: PRE-INSTALLATION CHECK ===
[ "$QUIET_MODE" != "true" ] && log_info "Phase 1: Pre-Installation System Check"
[ "$QUIET_MODE" != "true" ] && log_info "======================================="

piwik_log 'Pre-installation check' /bin/bash -c "export REMOTE_PS='${REMOTE_PS}'; export BRANCH_PS='${BRANCH_PS}'; export CI_MODE='${CI_MODE}'; export QUIET_MODE='${QUIET_MODE}'; export INSTALL_LOG='${INSTALL_LOG}'; $(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Core/pre_install.sh)"

# === PHASE 2: MAIN INSTALLATION ===
[ "$QUIET_MODE" != "true" ] && log_info "Phase 2: Main Installation Process"
[ "$QUIET_MODE" != "true" ] && log_info "=================================="

# Install Python with Miniforge
piwik_log 'Python installation' /bin/bash -c "export REMOTE_PS='${REMOTE_PS}'; export BRANCH_PS='${BRANCH_PS}'; export CI_MODE='${CI_MODE}'; export QUIET_MODE='${QUIET_MODE}'; export INSTALL_LOG='${INSTALL_LOG}'; $(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Python/install.sh)"

# Setup first year Python environment and packages
piwik_log 'Python environment setup' /bin/bash -c "export REMOTE_PS='${REMOTE_PS}'; export BRANCH_PS='${BRANCH_PS}'; export CI_MODE='${CI_MODE}'; export QUIET_MODE='${QUIET_MODE}'; export INSTALL_LOG='${INSTALL_LOG}'; $(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Python/first_year_setup.sh)"

# Install Visual Studio Code
piwik_log 'Visual Studio Code installation' /bin/bash -c "export REMOTE_PS='${REMOTE_PS}'; export BRANCH_PS='${BRANCH_PS}'; export CI_MODE='${CI_MODE}'; export QUIET_MODE='${QUIET_MODE}'; export INSTALL_LOG='${INSTALL_LOG}'; $(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/VSC/install.sh)"

[ "$QUIET_MODE" != "true" ] && log_info "Main installation phase completed"

# === PHASE 3: POST-INSTALLATION VERIFICATION ===
log_info "Phase 3: Post-Installation Verification"
log_info "========================================"

# Export the install log for post-install verification
export INSTALL_LOG

if piwik_log 'post_install_verification' /bin/bash -c "export REMOTE_PS='${REMOTE_PS}'; export BRANCH_PS='${BRANCH_PS}'; $(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Core/post_install.sh)"; then
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
