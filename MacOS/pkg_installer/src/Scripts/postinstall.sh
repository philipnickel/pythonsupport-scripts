#!/bin/bash

# DTU Python Installation Script (PKG Installer) - Debug Version
# This script mimics exactly what MacOS/Components/orchestrators/first_year_students.sh does

LOG_FILE="PLACEHOLDER_LOG_FILE"
# Redirect output to both log file and stdout so installer can see progress
exec > >(tee -a "$LOG_FILE") 2>&1

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
echo "▶ DTU Python Installer: Step 1/4 - Installing Python via Miniconda (5-10 minutes)..."
show_progress_log "Installing Python..." "INFO"
python_script=$(curl -fsSL --connect-timeout 30 "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Python/install.sh")
python_curl_ret=$?

if [ $python_curl_ret -ne 0 ]; then
    echo "$(date): DEBUG: Failed to download Python install script, exit code: $python_curl_ret"
    _python_ret=1
else
    echo "$(date): DEBUG: Successfully downloaded Python install script"
    echo "$(date): DEBUG: About to execute Python install as user: $USER_NAME"
    echo "▶ DTU Python Installer: Installing Homebrew and Miniconda, please wait..."
    
    # Execute with proper environment variables and timeout
    if timeout 600 sudo -u "$USER_NAME" bash -c "export REMOTE_PS='$REMOTE_PS'; export BRANCH_PS='$BRANCH_PS'; export PYTHON_VERSION_PS='3.11'; $python_script"; then
        _python_ret=0
        echo "$(date): DEBUG: Python installation completed successfully"
        echo "✅ DTU Python Installer: Python installation completed successfully"
        show_progress_log "✅ Python installation completed" "INFO"
    else
        _python_ret=$?
        echo "$(date): DEBUG: Python installation failed with exit code: $_python_ret"
        echo "❌ DTU Python Installer: Python installation failed"
        show_progress_log "❌ Python installation failed" "ERROR"
    fi
fi

# 2. Install VSCode using component - with better error handling
echo "▶ DTU Python Installer: Step 2/4 - Installing Visual Studio Code (1-2 minutes)..."
show_progress_log "Installing VSCode..." "INFO"
if [ $_python_ret -eq 0 ]; then
    vscode_script=$(curl -fsSL --connect-timeout 30 "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/VSC/install.sh")
    vscode_curl_ret=$?
    
    if [ $vscode_curl_ret -ne 0 ]; then
        echo "$(date): DEBUG: Failed to download VSCode install script, exit code: $vscode_curl_ret"
        _vsc_ret=1
    else
        echo "$(date): DEBUG: Successfully downloaded VSCode install script"
        echo "▶ DTU Python Installer: Downloading and installing Visual Studio Code..."
        
        # Execute with proper environment variables and timeout  
        if timeout 300 sudo -u "$USER_NAME" bash -c "export REMOTE_PS='$REMOTE_PS'; export BRANCH_PS='$BRANCH_PS'; $vscode_script"; then
            _vsc_ret=0
            echo "$(date): DEBUG: VSCode installation completed successfully"
            echo "✅ DTU Python Installer: Visual Studio Code installation completed successfully"
            show_progress_log "✅ VSCode installation completed" "INFO"
        else
            _vsc_ret=$?
            echo "$(date): DEBUG: VSCode installation failed with exit code: $_vsc_ret"
            echo "❌ DTU Python Installer: Visual Studio Code installation failed"
            show_progress_log "❌ VSCode installation failed" "ERROR"
        fi
    fi
else
    echo "$(date): DEBUG: Skipping VSCode installation due to Python failure"
    echo "⏭️ DTU Python Installer: Skipping Visual Studio Code (Python installation failed)"
    _vsc_ret=1
fi

# 3. Run first year Python setup (install specific version and packages)
echo "▶ DTU Python Installer: Step 3/4 - Installing Python 3.11 and packages (3-5 minutes)..."
if [ $_python_ret -eq 0 ]; then
    show_progress_log "Running first year Python environment setup..." "INFO"
    first_year_script=$(curl -fsSL --connect-timeout 30 "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Python/first_year_setup.sh")
    first_year_curl_ret=$?
    
    if [ $first_year_curl_ret -ne 0 ]; then
        echo "$(date): DEBUG: Failed to download first year setup script, exit code: $first_year_curl_ret"
        _first_year_ret=1
    else
        echo "$(date): DEBUG: Successfully downloaded first year setup script"
        echo "▶ DTU Python Installer: Installing Python 3.11 and packages (dtumathtools, pandas, etc.)..."
        
        # Execute with proper environment variables and timeout
        if timeout 300 sudo -u "$USER_NAME" bash -c "export REMOTE_PS='$REMOTE_PS'; export BRANCH_PS='$BRANCH_PS'; export PYTHON_VERSION_PS='3.11'; $first_year_script"; then
            _first_year_ret=0
            echo "$(date): DEBUG: First year Python setup completed successfully"
            echo "✅ DTU Python Installer: Python 3.11 and packages installed successfully"
            show_progress_log "✅ First year Python setup completed" "INFO"
        else
            _first_year_ret=$?
            echo "$(date): DEBUG: First year Python setup failed with exit code: $_first_year_ret"
            echo "❌ DTU Python Installer: Python 3.11 setup failed"
            show_progress_log "❌ First year Python setup failed" "ERROR"
        fi
    fi
else
    _first_year_ret=0  # Skip if Python installation failed
    echo "$(date): DEBUG: Skipping first year setup due to Python failure"
    echo "⏭️ DTU Python Installer: Skipping Python 3.11 setup (Python installation failed)"
    show_progress_log "Skipping first year setup (Python installation failed)" "WARN"
fi

# 4. Install VSCode extensions
echo "▶ DTU Python Installer: Step 4/4 - Installing VSCode Python extensions (1-2 minutes)..."
if [ $_vsc_ret -eq 0 ]; then
    show_progress_log "Installing VSCode extensions for Python development..." "INFO"
    extensions_script=$(curl -fsSL --connect-timeout 30 "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/VSC/install_extensions.sh")
    extensions_curl_ret=$?
    
    if [ $extensions_curl_ret -ne 0 ]; then
        echo "$(date): DEBUG: Failed to download extensions script, exit code: $extensions_curl_ret"
        _extensions_ret=1
    else
        echo "$(date): DEBUG: Successfully downloaded extensions script"
        echo "▶ DTU Python Installer: Installing Python extension and development tools..."
        
        # Execute with proper environment variables and timeout
        if timeout 180 sudo -u "$USER_NAME" bash -c "export REMOTE_PS='$REMOTE_PS'; export BRANCH_PS='$BRANCH_PS'; $extensions_script"; then
            _extensions_ret=0
            echo "$(date): DEBUG: VSCode extensions installation completed successfully"
            echo "✅ DTU Python Installer: VSCode Python extensions installed successfully"
            show_progress_log "✅ VSCode extensions installation completed" "INFO"
        else
            _extensions_ret=$?
            echo "$(date): DEBUG: VSCode extensions installation failed with exit code: $_extensions_ret"
            echo "⚠️ DTU Python Installer: VSCode extensions installation failed (optional)"
            show_progress_log "⚠️ VSCode extensions installation failed" "WARN"
        fi
    fi
else
    _extensions_ret=0  # Skip if VSCode installation failed
    echo "$(date): DEBUG: Skipping VSCode extensions due to VSCode failure"
    echo "⏭️ DTU Python Installer: Skipping VSCode extensions (VSCode installation failed)"
    show_progress_log "Skipping VSCode extensions (VSCode installation failed)" "WARN"
fi

echo "$(date): DEBUG: Installation results - Python: $_python_ret, VSCode: $_vsc_ret, FirstYear: $_first_year_ret, Extensions: $_extensions_ret"

# Check results and provide appropriate feedback (EXACTLY same logic as orchestrator)
if [ $_python_ret -ne 0 ]; then
    show_progress_log "❌ Python installation failed" "ERROR"
    echo "$(date): ERROR: Python installation failed"
elif [ $_vsc_ret -ne 0 ]; then
    show_progress_log "❌ VSCode installation failed" "ERROR"
    echo "$(date): ERROR: VSCode installation failed"
elif [ $_first_year_ret -ne 0 ]; then
    show_progress_log "❌ First year Python setup failed" "ERROR"
    echo "$(date): ERROR: First year Python setup failed"
elif [ $_extensions_ret -ne 0 ]; then
    show_progress_log "⚠️ VSCode extensions installation failed, but core installation succeeded" "WARN"
    show_progress_log "You can install extensions manually later" "INFO"
    echo "$(date): WARNING: VSCode extensions installation failed, but core installation succeeded"
else
    show_progress_log "🎉 All installations completed successfully!" "INFO"
    echo "$(date): SUCCESS: All installations completed successfully!"
    echo "🎉 DTU Python Installer: Installation completed successfully!"
    echo "▶ DTU Python Installer: You can now use Python 3.11, dtumathtools, pandas, and Visual Studio Code"
fi

# Track overall success/failure (same as orchestrator)
if [ $_python_ret -eq 0 ] && [ $_vsc_ret -eq 0 ] && [ $_first_year_ret -eq 0 ] && [ $_extensions_ret -eq 0 ]; then
    show_progress_log "All components installed successfully" "INFO"
    echo "$(date): All components installed successfully"
else
    show_progress_log "Some components failed to install" "WARN" 
    echo "$(date): Some components failed to install"
fi

# Create summary
SUMMARY_FILE="PLACEHOLDER_SUMMARY_FILE"
cat > "$SUMMARY_FILE" << EOF
DTU First Year Students Installation Complete!

Installation log: $LOG_FILE
Date: $(date)
User: $USER_NAME

Installation Results:
- Python (via Miniconda): $([ $_python_ret -eq 0 ] && echo "SUCCESS" || echo "FAILED")
- VSCode installation: $([ $_vsc_ret -eq 0 ] && echo "SUCCESS" || echo "FAILED")
- First year Python setup (3.11 + packages): $([ $_first_year_ret -eq 0 ] && echo "SUCCESS" || echo "FAILED")
- VSCode extensions: $([ $_extensions_ret -eq 0 ] && echo "SUCCESS" || echo "FAILED")

Next steps:
1. Open Terminal and type 'python3' to test Python
2. Open Visual Studio Code to start coding
3. Try importing: dtumathtools, pandas, numpy, matplotlib

For support: PLACEHOLDER_SUPPORT_EMAIL
EOF

show_progress_log "Debug script has finished. Summary created at: $SUMMARY_FILE" "INFO"
echo "$(date): DEBUG: Script finished successfully"

exit 0