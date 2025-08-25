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

# Load configuration - set defaults if variables not provided
REMOTE_PS=${REMOTE_PS:-"dtudk/pythonsupport-scripts"}
BRANCH_PS=${BRANCH_PS:-"main"}
echo "Loading config with REMOTE_PS='$REMOTE_PS' BRANCH_PS='$BRANCH_PS'"
CONFIG_URL="https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/config.sh"
CONFIG_FILE="/tmp/config_$$.sh"
echo "Downloading config from: $CONFIG_URL"

curl -fsSL "$CONFIG_URL" -o "$CONFIG_FILE"
curl_exit=$?
if [ $curl_exit -eq 0 ] && [ -s "$CONFIG_FILE" ]; then
    echo "Config downloaded successfully ($(wc -c < "$CONFIG_FILE") bytes)"
    echo "Sourcing config..."
    source "$CONFIG_FILE"
    rm -f "$CONFIG_FILE"
    
    # Verify critical variables are set
    if [ -z "$MINIFORGE_BASE_URL" ]; then
        echo "ERROR: MINIFORGE_BASE_URL not set after loading config"
        echo "Available environment variables:"
        env | grep -E "(MINIFORGE|PYTHON)" | sort
        exit 1
    fi
    
    echo "Config loaded successfully:"
    echo "  MINIFORGE_BASE_URL='$MINIFORGE_BASE_URL'"
    echo "  MINIFORGE_PATH='$MINIFORGE_PATH'"
else
    echo "ERROR: Failed to download config from $CONFIG_URL (exit code: $curl_exit)"
    [ -f "$CONFIG_FILE" ] && echo "File size: $(wc -c < "$CONFIG_FILE") bytes" || echo "File does not exist"
    rm -f "$CONFIG_FILE"
    exit 1
fi

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
  
  curl -fsSL "$MINIFORGE_URL" -o /tmp/miniforge.sh
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to download Miniforge installer"
    exit 1
  fi
  
  echo "Miniforge installer downloaded successfully ($(wc -c < /tmp/miniforge.sh) bytes)"
  
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

