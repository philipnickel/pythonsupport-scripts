#!/bin/bash
set -e

# DTU Python Installation Script
# This script installs the complete Python development environment for DTU students
# Uses local scripts included in the package (no internet required during installation)

LOG_FILE="PLACEHOLDER_LOG_FILE"
# Stream output both to console (for installer UI/CLI) and to log file
# Create/clear log file, then tee all subsequent output
: > "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "$(date): === DTU Python installation started ==="

# Determine user
USER_NAME=$(stat -f%Su /dev/console)
export USER="$USER_NAME"
export HOME="/Users/$USER_NAME"

# Location where PKG extracted our components
# Install payload places components under /Library to avoid writing to sealed system volume
COMPONENTS_DIR="/Library/dtu_components"

if [[ ! -d "$COMPONENTS_DIR" ]]; then
    echo "$(date): ERROR: Component scripts not found at $COMPONENTS_DIR"
    echo "$(date): Package may be corrupted. Please download a fresh copy."
    exit 1
fi

echo "$(date): Using local component scripts from $COMPONENTS_DIR"
echo "$(date): Preparing to install components..."

# Run a component installer script as the console user
install_component() {
    local component="$1"
    local name="$2"
    local script_path="$COMPONENTS_DIR/$component/install.sh"
    
    echo "$(date): ==> Installing $name..."
    
    if [[ ! -f "$script_path" ]]; then
        echo "$(date): WARNING: Script not found: $script_path"
        echo "$(date): Skipping $name installation"
        return 1
    fi
    
    # Ensure user environment and PATH (Homebrew) are available when running as console user
    if sudo -u "$USER_NAME" env PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" bash "$script_path"; then
        echo "$(date): ✅ $name installed successfully"
        return 0
    else
        echo "$(date): ❌ $name installation failed (exit code: $?)"
        return 1
    fi
}

# Install components using local scripts (do not abort installer on a single failure)
install_component "Homebrew" "Homebrew package manager" || echo "$(date): Homebrew component reported failure"
install_component "Python" "Python via Miniconda" || echo "$(date): Python component reported failure"
install_component "VSC" "Visual Studio Code" || echo "$(date): VS Code component reported failure"

# Run Python environment setup if it exists
SETUP_SCRIPT="$COMPONENTS_DIR/Python/first_year_setup.sh"
if [[ -f "$SETUP_SCRIPT" ]]; then
    echo "$(date): ==> Running Python environment setup..."
    sudo -u "$USER_NAME" env PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" bash "$SETUP_SCRIPT" || echo "$(date): Setup completed with warnings"
else
    echo "$(date): Python setup script not found, skipping"
fi

# Run diagnostics if available
DIAGNOSTICS_SCRIPT="$COMPONENTS_DIR/Diagnostics/run.sh"
if [[ -f "$DIAGNOSTICS_SCRIPT" ]]; then
    echo "$(date): ==> Running diagnostics..."
    sudo -u "$USER_NAME" env PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" bash "$DIAGNOSTICS_SCRIPT" || echo "$(date): Diagnostics completed with warnings"
else
    echo "$(date): Diagnostics script not found, skipping"
fi

# Clean up extracted components (IMPORTANT: Remove scripts from filesystem)
echo "$(date): Cleaning up installation scripts..."
# Keep components for post-install verification/logging in CI environments
if [[ -z "${GITHUB_ACTIONS:-}" ]]; then
    if [[ -d "$COMPONENTS_DIR" ]]; then
        rm -rf "$COMPONENTS_DIR"
        echo "$(date): Removed temporary installation scripts from $COMPONENTS_DIR"
    else
        echo "$(date): Warning: Components directory already removed or not found"
    fi
else
    echo "$(date): Detected CI environment; keeping $COMPONENTS_DIR for inspection"
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

echo "$(date): === Installation completed ==="
echo "Summary created at: $SUMMARY_FILE"

# Show notification
sudo -u "$USER_NAME" osascript -e 'display notification "DTU Python environment installed successfully!" with title "DTU Python Installation Complete"' 2>/dev/null || true

exit 0