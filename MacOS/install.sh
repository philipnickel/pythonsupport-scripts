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

# Create a temporary script for the installation process
TEMP_INSTALL_SCRIPT="/tmp/dtu_install_process_$$.sh"
cat > "$TEMP_INSTALL_SCRIPT" << EOF
#!/bin/bash
exec > "/tmp/dtu_install_output_$$.log" 2>&1

# Set strict error handling
set -e

# Set up installation logging
INSTALL_LOG="/tmp/dtu_install_\$(date +%Y%m%d_%H%M%S).log"

# Load simple utilities - always try remote first since this is typically run remotely
if ! eval "\$(curl -fsSL "https://raw.githubusercontent.com/\${REMOTE_PS}/\${BRANCH_PS}/MacOS/Components/Shared/simple_utils.sh")"; then
    echo "ERROR: Failed to load utilities from remote repository"
    exit 1
fi
LOCAL_MODE=false

# Error cleanup function
cleanup_on_error() {
    echo ""
    log_error "Installation failed. Cleaning up temporary files..."
    rm -f "\$TEMP_INSTALL_SCRIPT" "/tmp/dtu_install_exit_code_$$.txt"
    exit 1
}

# Set trap for cleanup on error
trap cleanup_on_error ERR

log_info "DTU First Year Students - Complete Setup"
log_info "========================================"
log_info "Installation log: $INSTALL_LOG"

# === PHASE 1: PRE-INSTALLATION CHECK ===
log_info "Phase 1: Pre-Installation System Check"
log_info "======================================="

piwik_log 'pre_install_check' /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/\${REMOTE_PS}/\${BRANCH_PS}/MacOS/Components/Core/pre_install.sh)"
log_success "Pre-installation check completed"

# === PHASE 2: MAIN INSTALLATION ===
log_info "Phase 2: Main Installation Process"
log_info "=================================="

# Install Python with Miniforge
log_info "Installing Python 3.11 with Miniforge..."
piwik_log 'python_install' /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/\${REMOTE_PS}/\${BRANCH_PS}/MacOS/Components/Python/install.sh)"
log_success "Python installation completed"

# Setup first year Python environment and packages
log_info "Setting up first year Python environment..."
piwik_log 'python_first_year_setup' /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/\${REMOTE_PS}/\${BRANCH_PS}/MacOS/Components/Python/first_year_setup.sh)"
log_success "Python environment setup completed"

# Install Visual Studio Code
log_info "Installing Visual Studio Code..."
piwik_log 'vscode_install' /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/\${REMOTE_PS}/\${BRANCH_PS}/MacOS/Components/VSC/install.sh)"
log_success "VS Code installation completed"

log_info "Main installation phase completed"

# === PHASE 3: POST-INSTALLATION VERIFICATION ===
log_info "Phase 3: Post-Installation Verification"
log_info "========================================"

# Export the install log for post-install verification
export INSTALL_LOG

if piwik_log 'post_install_verification' /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/\${REMOTE_PS}/\${BRANCH_PS}/MacOS/Components/Core/post_install.sh)"; then
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

log_info "DTU First Year Students setup completed"
echo $? > "/tmp/dtu_install_exit_code_$$.txt"
EOF

chmod +x "$TEMP_INSTALL_SCRIPT"

# Run installation in background and show progress
{
    # Start the installation process in background
    "$TEMP_INSTALL_SCRIPT" &
    INSTALL_PID=$!
    
    if [ "$CI_MODE" = "false" ]; then
        # Show native macOS progress dialog with live log updates (interactive mode only)
        osascript << EOF &
        set progress total steps to -1
        set progress completed steps to 0
        set progress description to "Installing DTU Python Environment..."
        set progress additional description to "Initializing installation process..."
        
        repeat
            delay 2
            -- Check if process is still running
            if (do shell script "ps -p $INSTALL_PID > /dev/null 2>&1; echo \$?") is not equal to "0" then
                exit repeat
            end if
            
            -- Get the last few lines of the log to show current activity
            try
                set logContent to (do shell script "tail -3 '/tmp/dtu_install_output_$$.log' 2>/dev/null | grep -E '\\[(INFO|SUCCESS|ERROR)\\]' | tail -1 | sed 's/\\[.*\\] //' | cut -c1-60")
                if logContent is not equal to "" then
                    set progress additional description to logContent & "..."
                end if
            end try
        end repeat
        
        set progress completed steps to 1
        set progress description to "Installation completed!"
        set progress additional description to "Finalizing setup and generating diagnostics..."
        delay 1
EOF
        PROGRESS_PID=$!
    else
        # CI mode - show simple text progress
        echo "Installation running in background..."
        while kill -0 $INSTALL_PID 2>/dev/null; do
            # Show last log line if available
            if [ -f "/tmp/dtu_install_output_$$.log" ]; then
                tail -1 "/tmp/dtu_install_output_$$.log" 2>/dev/null | grep -E '\[(INFO|SUCCESS|ERROR)\]' | sed 's/\[.*\] /[CI] /' || true
            fi
            sleep 3
        done
        PROGRESS_PID=""
    fi
    
    # Wait for installation to complete
    wait $INSTALL_PID
    INSTALL_EXIT_CODE=$?
    
    # Kill the progress dialog (only if not in CI mode)
    if [ -n "$PROGRESS_PID" ]; then
        kill $PROGRESS_PID 2>/dev/null || true
    fi
    
    # Read the actual exit code from the file
    if [ -f "/tmp/dtu_install_exit_code_$$.txt" ]; then
        INSTALL_EXIT_CODE=$(cat "/tmp/dtu_install_exit_code_$$.txt")
    fi
    
    # Show results
    echo ""
    if [ "$INSTALL_EXIT_CODE" -eq 0 ]; then
        # Show notification only in interactive mode
        if [ "$CI_MODE" = "false" ]; then
            osascript -e 'display notification "DTU Python environment installed successfully!" with title "Installation Complete" sound name "Glass"' 2>/dev/null || true
        fi
        echo "✅ Installation completed successfully!"
        echo ""
        echo "🎉 Your DTU Python environment is ready!"
        echo "• Python 3.11 with DTU mathematical tools"
        echo "• Visual Studio Code with Python extension"
        echo "• Complete diagnostic system"
        echo ""
        if [ "$CI_MODE" = "false" ]; then
            echo "To get started:"
            echo "• Open Terminal and type: code"
            echo "• Or find Visual Studio Code in Applications"
            echo ""
        fi
        echo "Need help? Visit: https://pythonsupport.dtu.dk"
        echo "Questions? Email: pythonsupport@dtu.dk"
    else
        # Show notification only in interactive mode
        if [ "$CI_MODE" = "false" ]; then
            osascript -e 'display notification "Installation encountered issues. Check the log for details." with title "Installation Issues" sound name "Basso"' 2>/dev/null || true
        fi
        echo "⚠️  Installation completed with issues."
        echo ""
        echo "Please check the installation log for details:"
        echo "📋 Log file: /tmp/dtu_install_output_$$.log"
        echo ""
        echo "For support:"
        echo "📧 Email: pythonsupport@dtu.dk"
        echo "🌐 Visit: https://pythonsupport.dtu.dk/install/macos/automated-error.html"
        echo ""
        if [ "$CI_MODE" = "false" ]; then
            echo "You can view the detailed log with:"
            echo "cat /tmp/dtu_install_output_$$.log"
        fi
    fi
    
    # Cleanup temporary files
    rm -f "$TEMP_INSTALL_SCRIPT" "/tmp/dtu_install_exit_code_$$.txt"
    
    exit $INSTALL_EXIT_CODE
}