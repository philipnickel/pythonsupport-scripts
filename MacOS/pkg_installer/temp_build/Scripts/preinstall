#!/bin/bash
set -e

# Pre-installation script for macOS DTU Python Installer
# Performs system checks and preparations before installation

LOG_FILE="/tmp/macos_dtu_python_install.log"

# Create log file
echo "$(date): Pre-installation checks started" > "$LOG_FILE"
exec >> "$LOG_FILE" 2>&1

# Check macOS version
OS_VERSION=$(sw_vers -productVersion)
echo "$(date): macOS version: $OS_VERSION"

# Check available disk space (require at least 2GB)
AVAILABLE_SPACE=$(df -g / | tail -1 | awk '{print $4}')
if [ "$AVAILABLE_SPACE" -lt 2 ]; then
    echo "$(date): ERROR: Insufficient disk space. Need at least 2GB, have ${AVAILABLE_SPACE}GB"
    exit 1
fi

echo "$(date): Available disk space: ${AVAILABLE_SPACE}GB"

# Note: Package includes all required scripts
echo "$(date): Package includes all installation scripts (offline installation supported)"
# Internet may still be required for downloading software packages during component installation

# Check if running as root (installer requirement)
if [ "$EUID" -ne 0 ]; then
    echo "$(date): ERROR: Installation must run as root"
    exit 1
fi

echo "$(date): Pre-installation checks completed successfully"
exit 0