#!/bin/bash
set -e

# DTU Python Installation Script
# This script installs the complete Python development environment for DTU students
# Uses local scripts included in the package (no internet required during installation)

LOG_FILE="PLACEHOLDER_LOG_FILE"
exec >> "$LOG_FILE" 2>&1

echo "$(date): DTU Python installation started"

# Load loading animation functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/loading_animations.sh" 2>/dev/null || {
    # Fallback if loading_animations.sh not found - define basic functions
    show_loading_dialog() { echo "Loading: $1" >> "$LOG_FILE"; }
    show_progress_notification() { echo "Progress: $1" >> "$LOG_FILE"; }
    show_step_dialog() { echo "Step: $3" >> "$LOG_FILE"; }
    show_completion_dialog() { echo "Complete: $2" >> "$LOG_FILE"; }
    show_animated_loading() { echo "Animated: $1" >> "$LOG_FILE"; }
    cleanup_loading_dialogs() { true; }
}

# Show installation header and start notification
START_TIME=$(date +%s)
show_installer_header
show_progress_log "Starting DTU Python installation (estimated 10-15 minutes)..." "INFO"

# Determine user
USER_NAME=$(stat -f%Su /dev/console)
export USER="$USER_NAME"
export HOME="/Users/$USER_NAME"

# Location where PKG extracted our components
# PKG extracts payload to root, so our components are at /dtu_components
COMPONENTS_DIR="/dtu_components"

if [[ ! -d "$COMPONENTS_DIR" ]]; then
    echo "$(date): ERROR: Component scripts not found at $COMPONENTS_DIR"
    echo "$(date): Package may be corrupted. Please download a fresh copy."
    exit 1
fi

echo "$(date): Using local component scripts from $COMPONENTS_DIR"

# Smart installation detection functions
check_homebrew_installed() {
    sudo -u "$USER_NAME" bash -c 'command -v brew >/dev/null 2>&1'
}

check_python_installed() {
    sudo -u "$USER_NAME" bash -c 'command -v conda >/dev/null 2>&1'
}

check_vscode_installed() {
    sudo -u "$USER_NAME" bash -c 'command -v code >/dev/null 2>&1 || [ -d "/Applications/Visual Studio Code.app" ]'
}

# Install component using local scripts with enhanced progress tracking and smart detection
install_component() {
    local component="$1"
    local name="$2"
    local step_number="$3"
    local total_steps="$4"
    local estimated_time="${5:-2-5 min}"
    local script_path="$COMPONENTS_DIR/$component/install.sh"
    
    # Smart detection logic
    local already_installed=false
    case "$component" in
        "Homebrew")
            if check_homebrew_installed; then
                already_installed=true
            fi
            ;;
        "Python")
            if check_python_installed; then
                already_installed=true
            fi
            ;;
        "VSC")
            if check_vscode_installed; then
                already_installed=true
            fi
            ;;
    esac
    
    # Show progress step
    show_progress_step "$step_number" "$total_steps" "Installing $name" "$estimated_time"
    
    if $already_installed; then
        echo "$(date): $name is already installed, skipping..."
        show_progress_log "✓ $name already installed - skipping installation" "INFO"
        show_component_progress "$name" "skipped" "$name is already installed"
        return 0
    fi
    
    echo "$(date): Installing $name..."
    show_component_progress "$name" "starting"
    
    if [[ ! -f "$script_path" ]]; then
        echo "$(date): WARNING: Script not found: $script_path"
        echo "$(date): Skipping $name installation"
        show_component_progress "$name" "failed" "Script not found at $script_path"
        return 1
    fi
    
    # Run the local script as the console user
    if sudo -u "$USER_NAME" bash "$script_path"; then
        echo "$(date): $name installed successfully"
        show_component_progress "$name" "completed"
        return 0
    else
        echo "$(date): $name installation failed (exit code: $?)"
        show_component_progress "$name" "failed" "Installation script returned error code $?"
        return 1
    fi
}

# Install components using local scripts (with detailed progress tracking)
TOTAL_STEPS=6
install_component "Homebrew" "Homebrew package manager" 1 $TOTAL_STEPS "2-3 min"
install_component "Python" "Python via Miniconda" 2 $TOTAL_STEPS "5-8 min"
install_component "VSC" "Visual Studio Code" 3 $TOTAL_STEPS "1-2 min"

# Run Python environment setup if it exists
SETUP_SCRIPT="$COMPONENTS_DIR/Python/first_year_setup.sh"
if [[ -f "$SETUP_SCRIPT" ]]; then
    show_progress_step "4" $TOTAL_STEPS "Configuring Python environment" "1-2 min"
    echo "$(date): Running Python environment setup..."
    show_component_progress "Python Environment" "starting"
    
    if sudo -u "$USER_NAME" bash "$SETUP_SCRIPT"; then
        show_component_progress "Python Environment" "completed"
    else
        echo "$(date): Setup completed with warnings"
        show_component_progress "Python Environment" "completed" "Setup completed with warnings"
    fi
else
    echo "$(date): Python setup script not found, skipping"
    show_component_progress "Python Environment" "failed" "Setup script not found"
fi

# Run diagnostics if available
DIAGNOSTICS_SCRIPT="$COMPONENTS_DIR/Diagnostics/run.sh"
if [[ -f "$DIAGNOSTICS_SCRIPT" ]]; then
    show_progress_step "5" $TOTAL_STEPS "Running installation diagnostics" "30 sec"
    echo "$(date): Running diagnostics..."
    show_component_progress "Installation Diagnostics" "starting"
    
    if sudo -u "$USER_NAME" bash "$DIAGNOSTICS_SCRIPT"; then
        show_component_progress "Installation Diagnostics" "completed"
    else
        echo "$(date): Diagnostics completed with warnings"
        show_component_progress "Installation Diagnostics" "completed" "Diagnostics completed with warnings"
    fi
else
    echo "$(date): Diagnostics script not found, skipping"
    show_component_progress "Installation Diagnostics" "failed" "Diagnostics script not found"
fi

# Clean up extracted components (IMPORTANT: Remove scripts from filesystem)
show_progress_step "6" $TOTAL_STEPS "Cleaning up installation files" "5 sec"
echo "$(date): Cleaning up installation scripts..."
show_component_progress "Cleanup" "starting"

if [[ -d "$COMPONENTS_DIR" ]]; then
    show_progress_log "Removing temporary installation files..." "INFO"
    rm -rf "$COMPONENTS_DIR"
    echo "$(date): Removed temporary installation scripts from $COMPONENTS_DIR"
    show_component_progress "Cleanup" "completed"
else
    echo "$(date): Warning: Components directory already removed or not found"
    show_component_progress "Cleanup" "completed" "Components directory already clean"
fi

# Create summary
SUMMARY_FILE="PLACEHOLDER_SUMMARY_FILE"
cat > "$SUMMARY_FILE" << EOF
DTU Python Installation Complete!

Installation log: $LOG_FILE
Date: $(date)
User: $USER_NAME

Components installed:
- Homebrew package manager
- Python (via Miniconda)
- Visual Studio Code
- Python development packages

Next steps:
1. Open Terminal and type 'python3' to test Python
2. Open Visual Studio Code to start coding
3. Check the installation log if you encounter issues

For support: PLACEHOLDER_SUPPORT_EMAIL
EOF

echo "$(date): Installation completed"
echo "Summary created at: $SUMMARY_FILE"

# Calculate installation time
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
TOTAL_TIME_MIN=$((TOTAL_TIME / 60))
TOTAL_TIME_SEC=$((TOTAL_TIME % 60))

# Show installation summary
if [[ $TOTAL_TIME_MIN -gt 0 ]]; then
    TIME_STRING="${TOTAL_TIME_MIN}m ${TOTAL_TIME_SEC}s"
else
    TIME_STRING="${TOTAL_TIME_SEC}s"
fi

show_installation_summary "Homebrew, Python, VS Code, Development packages" "$TIME_STRING"

# Show final completion notification (this will appear after installer closes)
show_completion_notification "true" "DTU Python Installation Complete!\\n\\nYour development environment is ready to use.\\n\\nNext steps:\\n• Open Terminal and type 'python3'\\n• Launch Visual Studio Code\\n• Check the summary at: $SUMMARY_FILE\\n\\nInstallation completed in $TIME_STRING"

# Cleanup any background processes
cleanup_processes

exit 0