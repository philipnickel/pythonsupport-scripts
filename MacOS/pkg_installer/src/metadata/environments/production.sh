#!/bin/bash
# Production Environment Configuration
# Settings for official production releases

# Production-specific settings
PKG_NAME="DtuPythonInstaller"
PKG_ID="dk.dtu.pythonsupport.dtupythoninstaller"
PKG_TITLE="DTU Python Installer"

# Production branch (always main)
BRANCH="main"

# Full production features
AUTO_INCREMENT_VERSION=true
INCLUDE_IMAGES=true
INCLUDE_BROWSER_SUMMARY=true

# Standard production paths
LOG_FILE="/tmp/macos_dtu_python_install.log"
SUMMARY_FILE="/tmp/macos_dtu_python_summary.txt"

# Production requirements
MIN_DISK_SPACE_GB=2

# Production validation
VALIDATE_SCRIPTS=true
VALIDATE_RESOURCES=true
VERBOSE_OUTPUT=false  # Clean output for production

# Sign the package if certificates are available
CODE_SIGNING_ENABLED="${CODE_SIGNING_ENABLED:-false}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"

echo "🚀 Production build configuration loaded"