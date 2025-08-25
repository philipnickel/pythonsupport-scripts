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

# Load simple utilities
eval "$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Shared/simple_utils.sh")"

log_info "Python (Miniforge) installation"

# Check if conda is already installed
if command -v conda >/dev/null 2>&1; then
  log_success "Conda is already installed"
  conda --version
else
  log_info "Installing Miniforge..."
  
  # Detect architecture and download Miniforge
  ARCH=$([ $(uname -m) == "arm64" ] && echo "arm64" || echo "x86_64")
  MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-${ARCH}.sh"
  
  curl -fsSL "$MINIFORGE_URL" -o /tmp/miniforge.sh
  check_exit_code "Failed to download Miniforge installer"
  
  bash /tmp/miniforge.sh -b -p "$HOME/miniforge3"
  check_exit_code "Failed to install Miniforge"
  
  rm -f /tmp/miniforge.sh
  
  # Initialize conda for shells
  "$HOME/miniforge3/bin/conda" init bash zsh
  check_exit_code "Failed to initialize conda"
fi

# Update PATH and source configurations
export PATH="$HOME/miniforge3/bin:$PATH"
[ -e ~/.bashrc ] && source ~/.bashrc 2>/dev/null || true
[ -e ~/.bash_profile ] && source ~/.bash_profile 2>/dev/null || true
[ -e ~/.zshrc ] && source ~/.zshrc 2>/dev/null || true

# Configure conda
conda config --set anaconda_anon_usage off 2>/dev/null || true
conda config --set channel_priority flexible

# Verify installation
python3 --version
conda --version

log_success "Miniforge installation completed successfully!"