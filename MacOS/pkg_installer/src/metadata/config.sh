#!/bin/bash
# DTU Python Installer - Simple Configuration

# Package Information
PKG_NAME="DtuPythonInstaller"
PKG_ID="dk.dtu.pythonsupport.dtupythoninstaller"
PKG_TITLE="DTU Python Installer"
PKG_DESCRIPTION="Complete Python development environment for DTU students on macOS"

# Version Management
VERSION_FILE="$SCRIPT_DIR/metadata/.version"

# Repository Information
REPO="philipnickel/pythonsupport-scripts"
BRANCH="main"

# Installation Paths
LOG_FILE="/tmp/macos_dtu_python_install.log"
SUMMARY_FILE="/tmp/macos_dtu_python_summary.txt"

# Build Settings
INCLUDE_IMAGES=true
INCLUDE_BROWSER_SUMMARY=true

# Contact Information
SUPPORT_EMAIL="python-support@dtu.dk"
COPYRIGHT_TEXT="© 2024 Technical University of Denmark (DTU). All rights reserved."

# Export all variables for use in other scripts
export PKG_NAME PKG_ID PKG_TITLE PKG_DESCRIPTION
export VERSION_FILE REPO BRANCH
export LOG_FILE SUMMARY_FILE
export INCLUDE_IMAGES INCLUDE_BROWSER_SUMMARY
export SUPPORT_EMAIL COPYRIGHT_TEXT