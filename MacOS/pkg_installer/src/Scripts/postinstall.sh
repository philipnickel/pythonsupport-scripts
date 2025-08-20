#!/bin/bash
set -e

# DTU Python Installation Script (PKG Installer)
# This script mimics exactly what MacOS/Components/orchestrators/first_year_students.sh does
# but runs during PKG installation

LOG_FILE="PLACEHOLDER_LOG_FILE"
exec >> "$LOG_FILE" 2>&1

echo "$(date): First year students orchestrator started (PKG installer version)"

# Determine user and set environment (exactly like the orchestrator)
USER_NAME=$(stat -f%Su /dev/console)
export USER="$USER_NAME"
export HOME="/Users/$USER_NAME"

# Set up the same environment variables as the orchestrator
export REMOTE_PS="PLACEHOLDER_REPO"
export BRANCH_PS="PLACEHOLDER_BRANCH"

# Load loading animation functions for progress display
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/loading_animations.sh" 2>/dev/null || {
    # Define minimal fallback functions
    show_progress_log() { echo "$(date '+%H:%M:%S') [${2:-INFO}] DTU Python Installer: $1"; }
    show_installer_header() { echo "=== DTU Python Installation ==="; }
}

show_installer_header
show_progress_log "Starting first year students installation..." "INFO"

# EXACTLY mirror the first_year_students.sh orchestrator logic:

# 1. Install Python using component (includes Homebrew as dependency)
show_progress_log "Installing Python..." "INFO"
if sudo -u "$USER_NAME" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Python/install.sh)"; then
    _python_ret=0
    show_progress_log "✅ Python installation completed" "INFO"
else
    _python_ret=$?
    show_progress_log "❌ Python installation failed" "ERROR"
fi

# 2. Install VSCode using component  
show_progress_log "Installing VSCode..." "INFO"
if sudo -u "$USER_NAME" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/VSC/install.sh)"; then
    _vsc_ret=0
    show_progress_log "✅ VSCode installation completed" "INFO"
else
    _vsc_ret=$?
    show_progress_log "❌ VSCode installation failed" "ERROR"
fi

# 3. Run first year Python setup (install specific version and packages)
if [ $_python_ret -eq 0 ]; then
    show_progress_log "Running first year Python environment setup..." "INFO"
    if sudo -u "$USER_NAME" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Python/first_year_setup.sh)"; then
        _first_year_ret=0
        show_progress_log "✅ First year Python setup completed" "INFO"
    else
        _first_year_ret=$?
        show_progress_log "❌ First year Python setup failed" "ERROR"
    fi
else
    _first_year_ret=0  # Skip if Python installation failed
    show_progress_log "Skipping first year setup (Python installation failed)" "WARN"
fi

# 4. Install VSCode extensions
if [ $_vsc_ret -eq 0 ]; then
    show_progress_log "Installing VSCode extensions for Python development..." "INFO"
    if sudo -u "$USER_NAME" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/VSC/install_extensions.sh)"; then
        _extensions_ret=0
        show_progress_log "✅ VSCode extensions installation completed" "INFO"
    else
        _extensions_ret=$?
        show_progress_log "⚠️ VSCode extensions installation failed" "WARN"
    fi
else
    _extensions_ret=0  # Skip if VSCode installation failed
    show_progress_log "Skipping VSCode extensions (VSCode installation failed)" "WARN"
fi

# Check results and provide appropriate feedback (EXACTLY same logic as orchestrator)
if [ $_python_ret -ne 0 ]; then
    show_progress_log "❌ Python installation failed" "ERROR"
    echo "$(date): ERROR: Python installation failed"
    exit 1
elif [ $_vsc_ret -ne 0 ]; then
    show_progress_log "❌ VSCode installation failed" "ERROR"
    echo "$(date): ERROR: VSCode installation failed"
    exit 1
elif [ $_first_year_ret -ne 0 ]; then
    show_progress_log "❌ First year Python setup failed" "ERROR"
    echo "$(date): ERROR: First year Python setup failed"
    exit 1
elif [ $_extensions_ret -ne 0 ]; then
    show_progress_log "⚠️ VSCode extensions installation failed, but core installation succeeded" "WARN"
    show_progress_log "You can install extensions manually later" "INFO"
    echo "$(date): WARNING: VSCode extensions installation failed, but core installation succeeded"
else
    show_progress_log "🎉 All installations completed successfully!" "INFO"
    echo "$(date): SUCCESS: All installations completed successfully!"
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

Components installed:
- Python (via Miniconda) with first year packages
- Visual Studio Code with Python extensions
- Complete development environment

Next steps:
1. Open Terminal and type 'python3' to test Python
2. Open Visual Studio Code to start coding
3. Try importing: dtumathtools, pandas, numpy, matplotlib

For support: PLACEHOLDER_SUPPORT_EMAIL
EOF

show_progress_log "Script has finished. Installation summary created at: $SUMMARY_FILE" "INFO"
echo "$(date): Script has finished. You may now close the terminal..."

exit 0