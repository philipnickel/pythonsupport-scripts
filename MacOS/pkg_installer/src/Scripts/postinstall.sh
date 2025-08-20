#!/bin/bash

# DTU Python Installation Script (PKG Installer) - Debug Version
# This script mimics exactly what MacOS/Components/orchestrators/first_year_students.sh does

LOG_FILE="PLACEHOLDER_LOG_FILE"
exec >> "$LOG_FILE" 2>&1

echo "$(date): DEBUG: First year students orchestrator started (PKG installer version)"

# Determine user and set environment (exactly like the orchestrator)
USER_NAME=$(stat -f%Su /dev/console)
export USER="$USER_NAME"
export HOME="/Users/$USER_NAME"

# Set up the same environment variables as the orchestrator
export REMOTE_PS="PLACEHOLDER_REPO"
export BRANCH_PS="PLACEHOLDER_BRANCH"

echo "$(date): DEBUG: User=$USER_NAME, Home=$HOME"
echo "$(date): DEBUG: Remote=$REMOTE_PS, Branch=$BRANCH_PS"

# Load loading animation functions for progress display
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/loading_animations.sh" 2>/dev/null || {
    # Define minimal fallback functions
    show_progress_log() { echo "$(date '+%H:%M:%S') [${2:-INFO}] DTU Python Installer: $1"; }
    show_installer_header() { echo "=== DTU Python Installation ==="; }
}

show_installer_header
show_progress_log "Starting first year students installation..." "INFO"

echo "$(date): DEBUG: About to test curl access to GitHub"
curl_test_url="https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Python/install.sh"
echo "$(date): DEBUG: Testing URL: $curl_test_url"

# Test curl access first
if curl -fsSL --connect-timeout 10 "$curl_test_url" | head -5; then
    echo "$(date): DEBUG: Curl test successful"
else
    echo "$(date): DEBUG: Curl test failed with exit code: $?"
    exit 1
fi

echo "$(date): DEBUG: About to start Python installation"

# 1. Install Python using component (includes Homebrew as dependency) - with better error handling
show_progress_log "Installing Python..." "INFO"
python_script=$(curl -fsSL --connect-timeout 30 "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Python/install.sh")
python_curl_ret=$?

if [ $python_curl_ret -ne 0 ]; then
    echo "$(date): DEBUG: Failed to download Python install script, exit code: $python_curl_ret"
    _python_ret=1
else
    echo "$(date): DEBUG: Successfully downloaded Python install script"
    echo "$(date): DEBUG: About to execute Python install as user: $USER_NAME"
    
    # Execute with proper environment variables passed to subprocess
    if sudo -u "$USER_NAME" bash -c "export REMOTE_PS='$REMOTE_PS'; export BRANCH_PS='$BRANCH_PS'; export PYTHON_VERSION_PS='3.11'; $python_script"; then
        _python_ret=0
        echo "$(date): DEBUG: Python installation completed successfully"
        show_progress_log "✅ Python installation completed" "INFO"
    else
        _python_ret=$?
        echo "$(date): DEBUG: Python installation failed with exit code: $_python_ret"
        show_progress_log "❌ Python installation failed" "ERROR"
    fi
fi

# 2. Install VSCode using component - with better error handling
show_progress_log "Installing VSCode..." "INFO"
if [ $_python_ret -eq 0 ]; then
    vscode_script=$(curl -fsSL --connect-timeout 30 "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/VSC/install.sh")
    vscode_curl_ret=$?
    
    if [ $vscode_curl_ret -ne 0 ]; then
        echo "$(date): DEBUG: Failed to download VSCode install script, exit code: $vscode_curl_ret"
        _vsc_ret=1
    else
        echo "$(date): DEBUG: Successfully downloaded VSCode install script"
        
        # Execute with proper environment variables passed to subprocess
        if sudo -u "$USER_NAME" bash -c "export REMOTE_PS='$REMOTE_PS'; export BRANCH_PS='$BRANCH_PS'; $vscode_script"; then
            _vsc_ret=0
            echo "$(date): DEBUG: VSCode installation completed successfully"
            show_progress_log "✅ VSCode installation completed" "INFO"
        else
            _vsc_ret=$?
            echo "$(date): DEBUG: VSCode installation failed with exit code: $_vsc_ret"
            show_progress_log "❌ VSCode installation failed" "ERROR"
        fi
    fi
else
    echo "$(date): DEBUG: Skipping VSCode installation due to Python failure"
    _vsc_ret=1
fi

# Skip the other steps for now to focus on the core issue
_first_year_ret=0
_extensions_ret=0

echo "$(date): DEBUG: Installation results - Python: $_python_ret, VSCode: $_vsc_ret"

# Simplified result checking - don't exit with failure to see what happens
if [ $_python_ret -eq 0 ] && [ $_vsc_ret -eq 0 ]; then
    show_progress_log "🎉 Basic installations completed successfully!" "INFO"
    echo "$(date): SUCCESS: Basic installations completed successfully!"
else
    show_progress_log "⚠️ Some installations failed, but continuing" "WARN"
    echo "$(date): WARNING: Some installations failed"
fi

# Create summary
SUMMARY_FILE="PLACEHOLDER_SUMMARY_FILE"
cat > "$SUMMARY_FILE" << EOF
DTU First Year Students Installation Debug Complete!

Installation log: $LOG_FILE
Date: $(date)
User: $USER_NAME

Debug Results:
- Python installation: $([ $_python_ret -eq 0 ] && echo "SUCCESS" || echo "FAILED")
- VSCode installation: $([ $_vsc_ret -eq 0 ] && echo "SUCCESS" || echo "FAILED")

For support: PLACEHOLDER_SUPPORT_EMAIL
EOF

show_progress_log "Debug script has finished. Summary created at: $SUMMARY_FILE" "INFO"
echo "$(date): DEBUG: Script finished successfully"

exit 0