#!/bin/bash
# @doc
# @name: Python First Year Setup
# @description: Sets up Python environment with conda for DTU first year students
# @category: Python
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/first_year_setup.sh)"
# @requirements: macOS system, Homebrew
# @notes: Installs miniconda, creates base environment with Python 3.11, installs essential packages
# @/doc

# Load master utilities (prefer local when installed via PKG)
if [ "${REMOTE_PS:-}" = "local-pkg" ] || [ "${BRANCH_PS:-}" = "local-pkg" ]; then
  # shellcheck disable=SC1091
  . "/usr/local/share/dtu-pythonsupport/Components/Shared/master_utils.sh"
else
  eval "$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Shared/master_utils.sh")"
fi

log_info "First year Python setup"

# Ensure conda and brew are discoverable for non-login shells
export PATH="/opt/homebrew/bin:/usr/local/bin:/opt/homebrew/Caskroom/miniconda/base/bin:/usr/local/Caskroom/miniconda/base/bin:$PATH"

# Check if conda is installed, if not install Python first
if ! command -v conda >/dev/null 2>&1; then
  log_info "Conda not found. Installing Python with Miniconda first..."
  if [ "${REMOTE_PS:-}" = "local-pkg" ] || [ "${BRANCH_PS:-}" = "local-pkg" ]; then
    /bin/bash "/usr/local/share/dtu-pythonsupport/Components/Python/install.sh"
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Python/install.sh)"
  fi
  
  # Source the shell profile to get conda in PATH
  [ -e ~/.bashrc ] && source ~/.bashrc
  hash -r
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