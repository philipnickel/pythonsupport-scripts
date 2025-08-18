#!/bin/bash
# @doc
# @name: Python Component Installer
# @description: Installs Python via Miniconda with essential packages for data science and academic work
# @category: Python
# @requires: macOS, Internet connection, Homebrew (will be installed if missing)
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/install.sh)"
# @example: PYTHON_VERSION_PS=3.11 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/.../Python/install.sh)"
# @notes: Uses master utility system for consistent error handling and logging. Script automatically installs Homebrew if not present. Supports multiple Python versions via PYTHON_VERSION_PS environment variable. Creates conda environments and installs essential data science packages.
# @author: Python Support Team
# @version: 2024-08-18
# @/doc

# Load master utilities
source <(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-macos-components}/MacOS/Components/Shared/master_utils.sh")

log_info "Python (Miniconda) installation"
log_info "Starting installation process..."

# Check for homebrew and install if needed
ensure_homebrew

# Install miniconda
# Check if miniconda is installed
log_info "Installing Miniconda..."
if conda --version > /dev/null; then
  log_success "Miniconda or anaconda is already installed"
else
  log_info "Miniconda or anaconda not found, installing Miniconda"
  brew install --cask miniconda
  check_exit_code "Failed to install Miniconda"
fi
clear -x

log_info "Initialising conda..."
conda init bash
check_exit_code "Failed to initialize conda for bash"

conda init zsh
check_exit_code "Failed to initialize conda for zsh"

# Anaconda has this package which tracks usage metrics
# We will disable this, and if it fails, so be it.
# I.e. we shouldn't check whether it actually succeeds
conda config --set anaconda_anon_usage off

# need to restart terminal to activate conda
# restart terminal and continue
# conda puts its source stuff in the bashrc file
[ -e ~/.bashrc ] && source ~/.bashrc

log_info "Showing where it is installed:"
conda info --base
check_exit_code "Failed to get conda base directory"

log_info "Updating environment variables"
hash -r
clear -x

# We will not install the Anaconda GUI
# There may be license issues due to DTU being
# a rather big institution. So our installation guides
# will be pre-cautious here, and remove the defaults channels.
log_info "Removing defaults channel (due to licensing problems)"
conda config --remove channels defaults
conda config --add channels conda-forge

# Sadly, there can be a deadlock here
# When channel_priority == strict
# newer versions of conda will sometimes be unable to downgrade.
# However, when channel_priority == flexible
# it will sometimes not revert the libmamba suite which breaks
# the following conda install commands.
# Hmmm.... :(
conda config --set channel_priority flexible

log_success "Installed Miniconda successfully!"