#!/bin/bash
set -e

# DTU Python Installation Script (PKG Installer)
# This script follows the same installation flow as MacOS/Components/orchestrators/first_year_students.sh
# but uses local scripts included in the package (no internet required during installation)

LOG_FILE="PLACEHOLDER_LOG_FILE"
exec >> "$LOG_FILE" 2>&1

echo "$(date): DTU Python installation started (first year students PKG installer)"

# Load loading animation functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/loading_animations.sh" 2>/dev/null || {
    # Fallback if loading_animations.sh not found - define basic functions
    show_progress_log() { echo "$(date '+%H:%M:%S') [${2:-INFO}] DTU Python Installer: $1"; }
    show_component_progress() { true; }
    show_installer_header() { echo "=== DTU Python Installation ==="; }
}

# Show installation header and start notification
START_TIME=$(date +%s)
show_installer_header
show_progress_log "Starting DTU First Year Students setup (estimated 10-15 minutes)..." "INFO"

# Determine user
USER_NAME=$(stat -f%Su /dev/console)
export USER="$USER_NAME"
export HOME="/Users/$USER_NAME"

# Location where PKG extracted our components
COMPONENTS_DIR="/dtu_components"

if [[ ! -d "$COMPONENTS_DIR" ]]; then
    echo "$(date): ERROR: Component scripts not found at $COMPONENTS_DIR"
    echo "$(date): Package may be corrupted. Please download a fresh copy."
    exit 1
fi

echo "$(date): Using local component scripts from $COMPONENTS_DIR"

# Install component function following first_year_students.sh pattern
install_component() {
    local component="$1"
    local name="$2"
    local script_path="$COMPONENTS_DIR/$component/install.sh"
    
    echo "$(date): Installing $name..."
    show_progress_log "Installing $name..." "INFO"
    
    if [[ ! -f "$script_path" ]]; then
        echo "$(date): ERROR: Script not found: $script_path"
        return 1
    fi
    
    # Run the local script as the console user
    if sudo -u "$USER_NAME" bash "$script_path"; then
        echo "$(date): $name installed successfully"
        show_progress_log "✅ $name installation completed" "INFO"
        return 0
    else
        local ret=$?
        echo "$(date): $name installation failed (exit code: $ret)"
        show_progress_log "❌ $name installation failed" "ERROR"
        return $ret
    fi
}

# Follow exact same installation order as first_year_students.sh orchestrator
# 1. Install Python (which includes Homebrew as dependency)
show_progress_log "Step 1/4: Installing Python via Miniconda..." "INFO"
install_component "Python" "Python via Miniconda"
_python_ret=$?

# 2. Install VSCode
show_progress_log "Step 2/4: Installing Visual Studio Code..." "INFO"  
install_component "VSC" "Visual Studio Code"
_vsc_ret=$?

# 3. Run first year Python setup (install specific version and packages)
if [ $_python_ret -eq 0 ]; then
    show_progress_log "Step 3/4: Running first year Python environment setup..." "INFO"
    SETUP_SCRIPT="$COMPONENTS_DIR/Python/first_year_setup.sh"
    if [[ -f "$SETUP_SCRIPT" ]]; then
        echo "$(date): Running first year Python environment setup..."
        if sudo -u "$USER_NAME" bash "$SETUP_SCRIPT"; then
            _first_year_ret=0
            show_progress_log "✅ First year Python setup completed" "INFO"
        else
            _first_year_ret=$?
            echo "$(date): First year setup failed (exit code: $_first_year_ret)"
            show_progress_log "❌ First year Python setup failed" "ERROR"
        fi
    else
        echo "$(date): First year setup script not found, skipping"
        _first_year_ret=0
    fi
else
    echo "$(date): Skipping first year setup (Python installation failed)"
    _first_year_ret=0  # Skip if Python installation failed
fi

# 4. Install VSCode extensions
if [ $_vsc_ret -eq 0 ]; then
    show_progress_log "Step 4/4: Installing VSCode extensions for Python development..." "INFO"
    EXTENSIONS_SCRIPT="$COMPONENTS_DIR/VSC/install_extensions.sh"
    if [[ -f "$EXTENSIONS_SCRIPT" ]]; then
        echo "$(date): Installing VSCode extensions..."
        if sudo -u "$USER_NAME" bash "$EXTENSIONS_SCRIPT"; then
            _extensions_ret=0
            show_progress_log "✅ VSCode extensions installation completed" "INFO"
        else
            _extensions_ret=$?
            echo "$(date): VSCode extensions installation failed (exit code: $_extensions_ret)"
            show_progress_log "⚠️ VSCode extensions installation failed" "WARN"
        fi
    else
        echo "$(date): VSCode extensions script not found, skipping"
        _extensions_ret=0
    fi
else
    echo "$(date): Skipping VSCode extensions (VSCode installation failed)"
    _extensions_ret=0  # Skip if VSCode installation failed
fi

# Check results and provide appropriate feedback (same logic as orchestrator)
if [ $_python_ret -ne 0 ]; then
    show_progress_log "❌ Python installation failed - installation cannot continue" "ERROR"
    echo "$(date): ERROR: Python installation failed"
    exit 1
elif [ $_vsc_ret -ne 0 ]; then
    show_progress_log "❌ VSCode installation failed - installation cannot continue" "ERROR"
    echo "$(date): ERROR: VSCode installation failed"
    exit 1
elif [ $_first_year_ret -ne 0 ]; then
    show_progress_log "❌ First year Python setup failed - installation cannot continue" "ERROR"
    echo "$(date): ERROR: First year Python setup failed"
    exit 1
elif [ $_extensions_ret -ne 0 ]; then
    show_progress_log "⚠️ VSCode extensions installation failed, but core installation succeeded" "WARN"
    echo "$(date): WARNING: VSCode extensions installation failed, but core installation succeeded"
    show_progress_log "ℹ️ You can install extensions manually later" "INFO"
else
    show_progress_log "🎉 All installations completed successfully!" "INFO"
    echo "$(date): SUCCESS: All installations completed successfully!"
fi

# Clean up extracted components (IMPORTANT: Remove scripts from filesystem)
echo "$(date): Cleaning up installation scripts..."
if [[ -d "$COMPONENTS_DIR" ]]; then
    show_progress_log "Removing temporary installation files..." "INFO"
    rm -rf "$COMPONENTS_DIR"
    echo "$(date): Removed temporary installation scripts from $COMPONENTS_DIR"
else
    echo "$(date): Warning: Components directory already removed or not found"
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

echo "$(date): Installation completed"
echo "Summary created at: $SUMMARY_FILE"

# Calculate installation time
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
TOTAL_TIME_MIN=$((TOTAL_TIME / 60))
TOTAL_TIME_SEC=$((TOTAL_TIME % 60))

if [[ $TOTAL_TIME_MIN -gt 0 ]]; then
    TIME_STRING="${TOTAL_TIME_MIN}m ${TOTAL_TIME_SEC}s"
else
    TIME_STRING="${TOTAL_TIME_SEC}s"
fi

echo "$(date): Installation completed in $TIME_STRING"
show_progress_log "🎯 DTU First Year Students setup completed in $TIME_STRING" "INFO"

# Final success/failure tracking (same as orchestrator)
if [ $_python_ret -eq 0 ] && [ $_vsc_ret -eq 0 ] && [ $_first_year_ret -eq 0 ] && [ $_extensions_ret -eq 0 ]; then
    echo "$(date): SUCCESS: All components installed successfully"
    exit 0
else
    echo "$(date): PARTIAL SUCCESS: Some components failed to install"
    exit 0  # Don't fail the PKG installation for extension failures
fi