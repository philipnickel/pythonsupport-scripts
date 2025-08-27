#!/bin/bash
# @doc
# @name: Python First Year Setup
# @description: Verifies Python environment setup for DTU first year students (packages now installed in main install script)
# @category: Python
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/first_year_setup.sh)"
# @requirements: macOS system with Miniforge already installed
# @notes: This script now primarily verifies the installation since packages are installed directly in base environment
# @/doc

# Set configuration defaults - no external config dependencies
REMOTE_PS=${REMOTE_PS:-"dtudk/pythonsupport-scripts"}
BRANCH_PS=${BRANCH_PS:-"main"}
MINIFORGE_PATH=${MINIFORGE_PATH:-"$HOME/miniforge3"}
DTU_PACKAGES=${DTU_PACKAGES:-"dtumathtools pandas scipy statsmodels uncertainties"}

# Load Piwik utility for analytics
#if curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared/piwik_utility.sh" -o /tmp/piwik_utility.sh 2>/dev/null && source /tmp/piwik_utility.sh 2>/dev/null; then
#    PIWIK_LOADED=true
#else
#    PIWIK_LOADED=false
#fi

# Set up install log for this script
[ -z "$INSTALL_LOG" ] && INSTALL_LOG="/tmp/dtu_install_$(date +%Y%m%d_%H%M%S).log"

# Source shell profiles to ensure conda is available
[ -e ~/.bashrc ] && source ~/.bashrc 2>/dev/null || true
[ -e ~/.bash_profile ] && source ~/.bash_profile 2>/dev/null || true  
[ -e ~/.zshrc ] && source ~/.zshrc 2>/dev/null || true

# Update PATH to include conda
export PATH="$MINIFORGE_PATH/bin:$PATH"

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
conda install python=${PYTHON_VERSION_PS:-3.12} dtumathtools pandas scipy statsmodels uncertainties -y
#if [ $? -ne 0 ]; then 
#  [ "$PIWIK_LOADED" = true ] && piwik_log 21  # First Year Setup fail
#  exit 1
#fi

#[ "$PIWIK_LOADED" = true ] && piwik_log 20  # First Year Setup success

clear -x
