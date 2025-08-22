#!/bin/bash
# @doc
# @name: Python First Year Setup
# @description: Sets up Python environment with conda for DTU first year students
# @category: Python
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/first_year_setup.sh)"
# @requirements: macOS system, Homebrew
# @notes: Installs miniconda, creates base environment with Python 3.11, installs essential packages
# @/doc

# Load master utilities
eval "$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Shared/master_utils.sh")"

log_info "First year Python setup"

# Load shell profile to get conda environment (conda init sets this up)
[ -e ~/.bashrc ] && source ~/.bashrc
[ -e ~/.bash_profile ] && source ~/.bash_profile
[ -e ~/.zshrc ] && source ~/.zshrc 2>/dev/null || true

# Check if conda is installed, if not install Python first
if ! command -v conda >/dev/null 2>&1; then
  log_info "Conda not found. Installing Python with Miniconda first..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Python/install.sh)"
  
  # Re-source shell profile after conda installation
  [ -e ~/.bashrc ] && source ~/.bashrc
  [ -e ~/.bash_profile ] && source ~/.bash_profile
  [ -e ~/.zshrc ] && source ~/.zshrc 2>/dev/null || true
fi



log_info "Ensuring Python version ${PYTHON_VERSION_PS:-3.11}..."
# Doing local strict channel-priority
conda install --strict-channel-priority python=${PYTHON_VERSION_PS:-3.11} -y
check_exit_code "Failed to install Python version ${PYTHON_VERSION_PS:-3.11}"
clear -x

log_info "Installing packages..."
conda install dtumathtools pandas scipy statsmodels uncertainties -y
check_exit_code "Failed to install required packages"
clear -x

log_success "Installed conda and related packages for 1st year at DTU!"