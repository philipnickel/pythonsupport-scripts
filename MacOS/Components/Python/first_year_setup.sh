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

log_info "First year Python setup verification"

# Source shell profiles to ensure conda is available
[ -e ~/.bashrc ] && source ~/.bashrc 2>/dev/null || true
[ -e ~/.bash_profile ] && source ~/.bash_profile 2>/dev/null || true  
[ -e ~/.zshrc ] && source ~/.zshrc 2>/dev/null || true

# Update PATH to include conda
export PATH="$HOME/miniforge3/bin:$PATH"

# Check if conda is installed, if not install Python first
if ! command -v conda >/dev/null 2>&1; then
  log_info "Conda not found. Installing Python with Miniforge first..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Python/install.sh)"
  
  # Re-source shell profile after conda installation
  [ -e ~/.bashrc ] && source ~/.bashrc 2>/dev/null || true
  [ -e ~/.bash_profile ] && source ~/.bash_profile 2>/dev/null || true
  [ -e ~/.zshrc ] && source ~/.zshrc 2>/dev/null || true
  export PATH="$HOME/miniforge3/bin:$PATH"
fi

# Verify Python version and packages (should already be installed by main install script)
log_info "Verifying Python ${PYTHON_VERSION_PS:-3.11} installation..."
EXPECTED_VERSION="${PYTHON_VERSION_PS:-3.11}"
INSTALLED_VERSION=$(python3 --version | cut -d " " -f 2)
if [[ "$INSTALLED_VERSION" != "$EXPECTED_VERSION"* ]]; then
  log_warning "Python version ($INSTALLED_VERSION) may not match expected version ($EXPECTED_VERSION)"
  log_info "Installing/updating Python version..."
  conda install python=${PYTHON_VERSION_PS:-3.11} -y
  check_exit_code "Failed to install Python version ${PYTHON_VERSION_PS:-3.11}"
fi

log_info "Verifying required packages..."
python3 -c "import dtumathtools, pandas, scipy, statsmodels, uncertainties; print('All packages verified successfully')" 2>/dev/null
if [ $? -ne 0 ]; then
  log_info "Some packages missing, installing them..."
  conda install dtumathtools pandas scipy statsmodels uncertainties -y
  check_exit_code "Failed to install required packages"
fi

clear -x
log_success "Python environment verified for DTU 1st year students!"