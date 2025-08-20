#!/bin/bash
# Local Testing Environment Configuration
# Settings for local development and testing

# Local testing settings
PKG_NAME="DtuPythonInstaller_LOCAL"
PKG_ID="dk.dtu.pythonsupport.dtupythoninstaller"
PKG_TITLE="DTU Python Installer (Local)"

# Use current branch for local testing
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "local")

# Local testing features (same as production)
AUTO_INCREMENT_VERSION=true  # Always increment version
INCLUDE_IMAGES=true
INCLUDE_BROWSER_SUMMARY=true

# Local testing paths
LOG_FILE="/tmp/macos_dtu_python_install.log"
SUMMARY_FILE="/tmp/macos_dtu_python_summary.txt"

# Standard requirements
MIN_DISK_SPACE_GB=2

# Local testing validation
VALIDATE_SCRIPTS=true
VALIDATE_RESOURCES=true
VERBOSE_OUTPUT=true    # Verbose for debugging

# Local build info
BUILD_USER="${USER:-unknown}"
BUILD_TIME=$(date +"%Y%m%d-%H%M%S")

echo "🧪 Local testing build configuration loaded"
echo "   User: $BUILD_USER"
echo "   Branch: $BRANCH"
echo "   Time: $BUILD_TIME"