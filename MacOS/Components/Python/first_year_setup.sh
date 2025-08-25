#!/bin/bash
# @doc
# @name: Python First Year Setup
# @description: Verifies Python environment setup for DTU first year students (packages now installed in main install script)
# @category: Python
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/first_year_setup.sh)"
# @requirements: macOS system with Miniforge already installed
# @notes: This script now primarily verifies the installation since packages are installed directly in base environment
# @/doc

# Load utilities with new filename to break CDN cache
eval "$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared/common.sh")"


# Source shell profiles to ensure conda is available
[ -e ~/.bashrc ] && source ~/.bashrc 2>/dev/null || true
[ -e ~/.bash_profile ] && source ~/.bash_profile 2>/dev/null || true  
[ -e ~/.zshrc ] && source ~/.zshrc 2>/dev/null || true

# Update PATH to include conda
export PATH="$HOME/miniforge3/bin:$PATH"

# Check if conda is installed, if not install Python first
if ! command -v conda >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Python/install.sh)"
  
  # Re-source shell profile after conda installation
  [ -e ~/.bashrc ] && source ~/.bashrc 2>/dev/null || true
  [ -e ~/.bash_profile ] && source ~/.bash_profile 2>/dev/null || true
  [ -e ~/.zshrc ] && source ~/.zshrc 2>/dev/null || true
  export PATH="$HOME/miniforge3/bin:$PATH"
fi

# Install required packages without verification (verification happens in post-install)
conda install python=${PYTHON_VERSION_PS:-3.11} dtumathtools pandas scipy statsmodels uncertainties -y
if [ $? -ne 0 ]; then exit 1; fi

clear -x
