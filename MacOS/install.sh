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

# Set output mode based on verbose flag/environment
if [ "$VERBOSE_MODE" = "true" ]; then
    QUIET_MODE=false
    echo "Running in verbose mode"
    echo ""
else
    # Default to quiet mode for clean user experience
    QUIET_MODE=true
    
    echo "This installation requires administrator privileges."
    echo "You will be prompted to enter your system password."
    echo ""
    echo "Installation progress will be shown below."
    echo "Detailed logs are being written to: /tmp/dtu_install_$(date +%Y%m%d_%H%M%S).log"
    echo ""
    echo "For verbose output, run: $0 --verbose"
    echo ""
fi

# Export modes for child scripts  
export QUIET_MODE
export VERBOSE_MODE

# === PROGRESS DISPLAY FUNCTIONS ===
# Run command with progress indication (only used in main installer)
run_with_progress() {
    local event_name="$1"
    shift
    
    log "Starting: $event_name"
    
    local exit_code
    
    # Execute command and capture all output to log file
    if [ "$QUIET_MODE" = "true" ]; then
        # In quiet mode, show progress spinner
        printf "Processing $event_name... "
        
        # Run command in background
        ("$@") >> "$INSTALL_LOG" 2>&1 &
        local cmd_pid=$!
        
        # Simple spinner animation
        local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
        local i=0
        while kill -0 $cmd_pid 2>/dev/null; do
            printf "\rProcessing $event_name... ${chars:$i:1}"
            i=$(((i + 1) % ${#chars}))
            sleep 0.1
        done
        
        # Get exit code and show result
        wait $cmd_pid
        exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            printf "\r✓ $event_name completed\n"
        else
            printf "\r✗ $event_name failed\n"
        fi
    else
        # In verbose mode, show output normally
        local output
        output=$("$@" 2>&1)
        exit_code=$?
        echo "$output" | tee -a "$INSTALL_LOG"
    fi
    
    log "Completed: $event_name (exit code: $exit_code)"
    return $exit_code
}

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
echo "Mode: QUIET_MODE=$QUIET_MODE, VERBOSE_MODE=$VERBOSE_MODE" >> "$INSTALL_LOG"
echo "" >> "$INSTALL_LOG"

log "DTU First Year Students - Complete Setup"
log "========================================"
log "Installation log: $INSTALL_LOG"

# === PHASE 1: PRE-INSTALLATION CHECK ===
[ "$QUIET_MODE" != "true" ] && log "Phase 1: Pre-Installation System Check"
[ "$QUIET_MODE" != "true" ] && log "======================================="

# Analytics can be added here if needed
run_with_progress 'Pre-installation check' /bin/bash -c "export REMOTE_PS='${REMOTE_PS}'; export BRANCH_PS='${BRANCH_PS}'; export QUIET_MODE='${QUIET_MODE}'; export VERBOSE_MODE='${VERBOSE_MODE}'; export INSTALL_LOG='${INSTALL_LOG}'; $(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Core/pre_install.sh)"

# === PHASE 2: MAIN INSTALLATION ===
[ "$QUIET_MODE" != "true" ] && log "Phase 2: Main Installation Process"
[ "$QUIET_MODE" != "true" ] && log "=================================="

# Install Python with Miniforge
run_with_progress 'Python installation' /bin/bash -c "export REMOTE_PS='${REMOTE_PS}'; export BRANCH_PS='${BRANCH_PS}'; export QUIET_MODE='${QUIET_MODE}'; export VERBOSE_MODE='${VERBOSE_MODE}'; export INSTALL_LOG='${INSTALL_LOG}'; $(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Python/install.sh)"

# Setup first year Python environment and packages
run_with_progress 'Python environment setup' /bin/bash -c "export REMOTE_PS='${REMOTE_PS}'; export BRANCH_PS='${BRANCH_PS}'; export QUIET_MODE='${QUIET_MODE}'; export VERBOSE_MODE='${VERBOSE_MODE}'; export INSTALL_LOG='${INSTALL_LOG}'; $(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Python/first_year_setup.sh)"

# Install Visual Studio Code
run_with_progress 'Visual Studio Code installation' /bin/bash -c "export REMOTE_PS='${REMOTE_PS}'; export BRANCH_PS='${BRANCH_PS}'; export QUIET_MODE='${QUIET_MODE}'; export VERBOSE_MODE='${VERBOSE_MODE}'; export INSTALL_LOG='${INSTALL_LOG}'; $(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/VSC/install.sh)"

[ "$QUIET_MODE" != "true" ] && log "Main installation phase completed"

# === PHASE 3: POST-INSTALLATION VERIFICATION ===
log "Phase 3: Post-Installation Verification"
log "========================================"

# Export the install log for post-install verification
export INSTALL_LOG

if run_with_progress 'Post-installation verification' /bin/bash -c "export REMOTE_PS='${REMOTE_PS}'; export BRANCH_PS='${BRANCH_PS}'; $(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Core/post_install.sh)"; then
    log "Post-installation verification completed successfully"
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
    log "Post-installation verification detected issues"
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
