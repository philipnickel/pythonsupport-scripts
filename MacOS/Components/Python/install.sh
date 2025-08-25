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

# Load master utilities
eval "$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Shared/master_utils.sh")"

log_info "Python (Miniforge) installation"
log_info "Starting installation process..."

# Check if conda is already installed
log_info "Checking for existing conda installation..."
if command -v conda >/dev/null 2>&1; then
  log_success "Conda is already installed"
  conda --version
else
  log_info "Installing Miniforge..."
  
  # Detect architecture
  if [[ $(uname -m) == "arm64" ]]; then
    ARCH="arm64"
  else
    ARCH="x86_64"
  fi
  
  # Download and install Miniforge
  MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-${ARCH}.sh"
  
  log_info "Downloading Miniforge for ${ARCH}..."
  curl -fsSL "$MINIFORGE_URL" -o /tmp/miniforge.sh
  check_exit_code "Failed to download Miniforge installer"
  
  log_info "Installing Miniforge (this may take a few minutes)..."
  bash /tmp/miniforge.sh -b -p "$HOME/miniforge3"
  check_exit_code "Failed to install Miniforge"
  
  # Clean up installer
  rm -f /tmp/miniforge.sh
  
  # Add to PATH
  export PATH="$HOME/miniforge3/bin:$PATH"
  
  log_info "Initializing conda..."
  "$HOME/miniforge3/bin/conda" init bash
  check_exit_code "Failed to initialize conda for bash"
  
  "$HOME/miniforge3/bin/conda" init zsh
  check_exit_code "Failed to initialize conda for zsh"
fi

clear -x

# Source shell configurations to get conda in PATH
[ -e ~/.bashrc ] && source ~/.bashrc 2>/dev/null || true
[ -e ~/.bash_profile ] && source ~/.bash_profile 2>/dev/null || true
[ -e ~/.zshrc ] && source ~/.zshrc 2>/dev/null || true

# Update PATH to include conda
export PATH="$HOME/miniforge3/bin:$PATH"

# Disable conda's usage tracking
conda config --set anaconda_anon_usage off 2>/dev/null || true

log_info "Showing conda installation location:"
conda info --base
check_exit_code "Failed to get conda base directory"

log_info "Updating environment variables..."
hash -r
clear -x

# Configure conda channels (conda-forge is default in Miniforge)
log_info "Configuring conda channels..."
conda config --set channel_priority flexible
conda config --show channels

# Install Python and required packages directly in base environment
log_info "Installing Python ${PYTHON_VERSION_PS:-3.11} and packages in base environment..."
conda install python=${PYTHON_VERSION_PS:-3.11} dtumathtools pandas scipy statsmodels uncertainties -y
check_exit_code "Failed to install Python and packages"

clear -x
log_success "Miniforge installation completed successfully!"

# Verify installation
log_info "Verifying installation..."
python3 --version
conda --version
python3 -c "import dtumathtools, pandas, scipy, statsmodels, uncertainties; print('All packages imported successfully')"
check_exit_code "Package verification failed"

log_success "All packages verified successfully!"