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

# Set configuration defaults - no external config dependencies
REMOTE_PS=${REMOTE_PS:-"dtudk/pythonsupport-scripts"}
BRANCH_PS=${BRANCH_PS:-"main"}

# Load Piwik utility for analytics
#if curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared/piwik_utility.sh" -o /tmp/piwik_utility.sh 2>/dev/null && source /tmp/piwik_utility.sh 2>/dev/null; then
#    PIWIK_LOADED=true
#else
#    PIWIK_LOADED=false
#fi

# Set defaults for required variables
PYTHON_VERSION_DTU=${PYTHON_VERSION_DTU:-"3.12"}
MINIFORGE_PATH=${MINIFORGE_PATH:-"$HOME/miniforge3"}
MINIFORGE_BASE_URL=${MINIFORGE_BASE_URL:-"https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX"}

echo "Python installation configuration:"
echo "  PYTHON_VERSION_DTU='$PYTHON_VERSION_DTU'"
echo "  MINIFORGE_PATH='$MINIFORGE_PATH'"
echo "  MINIFORGE_BASE_URL='$MINIFORGE_BASE_URL'"

# Set up install log for this script
[ -z "$INSTALL_LOG" ] && INSTALL_LOG="/tmp/dtu_install_$(date +%Y%m%d_%H%M%S).log"

# Check if conda is already installed
if command -v conda >/dev/null 2>&1; then
  conda --version
else
  
  # Download and install Miniforge
  ARCH=$(uname -m)
  MINIFORGE_URL="${MINIFORGE_BASE_URL}-${ARCH}.sh"
  echo "Downloading Miniforge for $ARCH from: $MINIFORGE_URL"
  
  # Test URL accessibility first
  if ! curl -fsSL -I "$MINIFORGE_URL" >/dev/null 2>&1; then
    echo "ERROR: Miniforge URL is not accessible: $MINIFORGE_URL"
    exit 1
  fi
  
  # Create secure temporary directory
  temp_dir=$(mktemp -d)
  temp_installer="$temp_dir/miniforge.sh"
  
  curl -fsSL "$MINIFORGE_URL" -o "$temp_installer"
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to download Miniforge installer"
    rm -rf "$temp_dir"
    exit 1
  fi
  
  echo "Miniforge installer downloaded successfully ($(wc -c < "$temp_installer") bytes)"
  
  bash "$temp_installer" -b -p "$MINIFORGE_PATH"
  #if [ $? -ne 0 ]; then 
  #  [ "$PIWIK_LOADED" = true ] && piwik_log 11  # Python Installation fail
  #  rm -rf "$temp_dir"
  #  exit 1
  #fi
  
  #[ "$PIWIK_LOADED" = true ] && piwik_log 10  # Python Installation success
  
  rm -rf "$temp_dir"
  
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

