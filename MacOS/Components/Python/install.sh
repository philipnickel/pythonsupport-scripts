#!/bin/bash
# @doc
# @name: Python Component Installer (Miniforge)
# @description: Installs Python via Miniforge without Homebrew dependency
# @category: Python
# @requires: macOS, Internet connection
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/install.sh)"
# @example: PYTHON_VERSION_PS=3.11 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/install.sh)"
# @notes: Uses master utility system for consistent error handling and logging. Installs Miniforge directly from GitHub releases. Supports multiple Python versions via PYTHON_VERSION_PS environment variable.
# @author: Python Support Team
# @version: 2024-12-25
# @/doc

# Load configuration
echo "DEBUG: REMOTE_PS='$REMOTE_PS' BRANCH_PS='$BRANCH_PS'"
if [ -z "$REMOTE_PS" ] || [ -z "$BRANCH_PS" ]; then
    echo "ERROR: REMOTE_PS and BRANCH_PS must be set"
    exit 1
fi
source <(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/config.sh")

# Set up install log for this script
[ -z "$INSTALL_LOG" ] && INSTALL_LOG="/tmp/dtu_install_$(date +%Y%m%d_%H%M%S).log"

# Check if conda is already installed
if command -v conda >/dev/null 2>&1; then
  conda --version
else
  
  # Download and install Miniforge
  ARCH=$(uname -m)
  MINIFORGE_URL="${MINIFORGE_BASE_URL}-${ARCH}.sh"
  curl -fsSL "$MINIFORGE_URL" -o /tmp/miniforge.sh
  if [ $? -ne 0 ]; then exit 1; fi
  
  bash /tmp/miniforge.sh -b -p "$MINIFORGE_PATH"
  if [ $? -ne 0 ]; then exit 1; fi
  
  rm -f /tmp/miniforge.sh
  
  # Initialize conda for shells
  "$HOME/miniforge3/bin/conda" init bash zsh
  if [ $? -ne 0 ]; then exit 1; fi
fi

# Update PATH and source configurations
export PATH="$HOME/miniforge3/bin:$PATH"
[ -e ~/.bashrc ] && source ~/.bashrc 2>/dev/null || true
[ -e ~/.bash_profile ] && source ~/.bash_profile 2>/dev/null || true
[ -e ~/.zshrc ] && source ~/.zshrc 2>/dev/null || true

# Configure conda
conda config --set anaconda_anon_usage off 2>/dev/null || true
conda config --set channel_priority flexible

