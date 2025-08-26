#!/bin/bash
# DTU Python Support - macOS Installer Release
# Version: 1.0.0
# Double-click to install Python development environment for DTU students

# Set release configuration for local testing (configured for current fork/branch)
export REMOTE_PS="${REMOTE_PS:-philipnickel/pythonsupport-scripts}"
export BRANCH_PS="${BRANCH_PS:-MacOS_DEV}"
export DTU_INSTALLER_VERSION="1.0.0"

# DTU Python installer configuration

# Configuration (inline instead of external config.sh)
export PYTHON_VERSION_DTU="3.12"
export DTU_PACKAGES="dtumathtools pandas scipy statsmodels uncertainties"
export VSCODE_EXTENSIONS="ms-python.python ms-python.pylint ms-toolsai.jupyter tomoki1207.pdf"
export MINIFORGE_PATH="$HOME/miniforge3"
export MINIFORGE_BASE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX"

echo "🍎 DTU Python Support - macOS Installer"
echo "========================================"
echo "This will install Python and VS Code for DTU coursework"
echo "Repository: $REMOTE_PS"
echo "Branch: $BRANCH_PS"
echo "PIS_ENV: ${PIS_ENV:-not set}"
echo ""

# Export all variables so they're available to child processes
export REMOTE_PS
export BRANCH_PS  
export PIS_ENV
export PYTHON_VERSION_DTU
export DTU_PACKAGES
export VSCODE_EXTENSIONS
export MINIFORGE_PATH
export MINIFORGE_BASE_URL

# Execute main installer with environment variables passed through
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/install.sh)"