#!/bin/bash
# DTU Python Support - macOS GUI Installer Wrapper
# Version: 1.0.0
# 
# This is a wrapper script that downloads and executes the main installer in GUI mode.
# Users can download this file and double-click to run the installation.
# 
# Usage:
#   Double-click this file to run the GUI installer
#   Or run: bash dtu-python-installer-macos-gui.sh

# Set the repository and branch for the main installer
REMOTE_PS="dtudk/pythonsupport-scripts"
BRANCH_PS="main"

# Set environment variable to ensure GUI mode
export DTU_CLI_MODE="false"

echo "DTU Python Support - macOS GUI Installer"
echo "==========================================="
echo "Downloading and starting the installation process..."
echo ""

# Download and execute the main installer in GUI mode
curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/releases/dtu-python-installer-macos.sh" | bash

# The script will exit with the same code as the main installer
exit $?
