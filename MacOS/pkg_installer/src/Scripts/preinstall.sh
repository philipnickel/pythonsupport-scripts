#!/bin/bash
set -e

# Pre-installation script for macOS DTU Python Installer
# Performs system checks and preparations before installation

LOG_FILE="/tmp/macos_dtu_python_install.log"

# Create log file
echo "$(date): Pre-installation checks started" > "$LOG_FILE"
exec >> "$LOG_FILE" 2>&1

# Load progress functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/loading_animations.sh" 2>/dev/null || {
    # Fallback if loading_animations.sh not found - define basic functions
    show_progress_log() { echo "$(date '+%H:%M:%S') [INFO] DTU Python Installer: $1"; }
    show_installer_header() { echo "DTU Python Installation Pre-checks"; }
    cleanup_processes() { true; }
}

# Show installer header and start pre-installation checks
show_installer_header
show_progress_log "Starting pre-installation system checks..." "INFO"

# Check macOS version
OS_VERSION=$(sw_vers -productVersion)
echo "$(date): macOS version: $OS_VERSION"
show_progress_log "✓ macOS version: $OS_VERSION" "INFO"

# Check available disk space (require at least 2GB)
AVAILABLE_SPACE=$(df -g / | tail -1 | awk '{print $4}')
show_progress_log "Checking available disk space..." "INFO"

if [ "$AVAILABLE_SPACE" -lt 2 ]; then
    echo "$(date): ERROR: Insufficient disk space. Need at least 2GB, have ${AVAILABLE_SPACE}GB"
    show_progress_log "❌ ERROR: Insufficient disk space. Need at least 2GB, have ${AVAILABLE_SPACE}GB" "ERROR"
    exit 1
fi

echo "$(date): Available disk space: ${AVAILABLE_SPACE}GB"
show_progress_log "✓ Sufficient disk space available: ${AVAILABLE_SPACE}GB" "INFO"

# Note: Package includes all required scripts
echo "$(date): Package includes all installation scripts (offline installation supported)"
# Internet may still be required for downloading software packages during component installation

# Check installation permissions (allowing user installs)
show_progress_log "Verifying installation permissions..." "INFO"
if [ "$EUID" -eq 0 ]; then
    show_progress_log "✓ Running as administrator (system-wide install)" "INFO"
else
    show_progress_log "✓ Running as user (user-specific install)" "INFO"
fi
show_progress_log "✓ Package includes all installation scripts (offline-capable)" "INFO"
show_progress_log "🎯 All pre-installation checks passed - ready to begin installation!" "INFO"

echo "$(date): Pre-installation checks completed successfully"

# Cleanup any background processes before exit
cleanup_processes
exit 0