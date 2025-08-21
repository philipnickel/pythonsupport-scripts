#!/bin/bash
# @doc
# @name: Python Component Installer
# @description: Installs Python via Miniconda with essential packages for data science and academic work
# @category: Python
# @requires: macOS, Internet connection, Homebrew (will be installed if missing)
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/install.sh)"
# @example: PYTHON_VERSION_PS=3.11 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/install.sh)"
# @notes: Uses master utility system for consistent error handling and logging. Script automatically installs Homebrew if not present. Supports multiple Python versions via PYTHON_VERSION_PS environment variable. Creates conda environments and installs essential data science packages.
# @author: Python Support Team
# @version: 2024-08-18
# @/doc

# Load master utilities (prefer local when installed via PKG)
if [ "${REMOTE_PS:-}" = "local-pkg" ] || [ "${BRANCH_PS:-}" = "local-pkg" ]; then
  # shellcheck disable=SC1091
  . "/usr/local/share/dtu-pythonsupport/Components/Shared/master_utils.sh"
else
  eval "$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Shared/master_utils.sh")"
fi

log_info "Python (Miniconda) installation"
log_info "Starting installation process..."

# Check for homebrew and install if needed
ensure_homebrew

# Install miniconda
# Check if miniconda is installed
log_info "Installing Miniconda..."
# Ensure non-login shell can find brew and potential conda locations
export PATH="/opt/homebrew/bin:/usr/local/bin:/opt/homebrew/Caskroom/miniconda/base/bin:/usr/local/Caskroom/miniconda/base/bin:$PATH"

if conda --version > /dev/null 2>&1; then
  log_success "Miniconda or anaconda is already installed"
else
  log_info "Miniconda or anaconda not found, installing Miniconda via Homebrew cask"
  export HOMEBREW_NO_AUTO_UPDATE=1
  if brew install --cask miniconda; then
    log_success "Installed Miniconda cask"
  else
    log_error "Homebrew cask 'miniconda' failed; trying 'miniforge' as fallback"
    if brew install --cask miniforge; then
      log_success "Installed Miniforge cask"
    else
      log_error "Homebrew cask 'miniforge' failed; falling back to official Miniconda installer"
      tmp_installer="$(mktemp -t miniconda-installer).sh"
      arch=$(uname -m)
      if [ "$arch" = "arm64" ]; then
        url="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
      else
        url="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
      fi
      curl -fsSL "$url" -o "$tmp_installer"
      check_exit_code "Failed to download Miniconda installer"
      bash "$tmp_installer" -b -p "$HOME/miniconda3"
      check_exit_code "Failed to run Miniconda installer"
      rm -f "$tmp_installer"
      log_success "Installed Miniconda via official installer"
    fi
  fi
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
hash -r

# Attempt to source conda.sh if conda not yet on PATH in non-interactive shells
if ! command -v conda >/dev/null 2>&1; then
  for conda_sh in \
    "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" \
    "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh" \
    "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh" \
    "/usr/local/Caskroom/miniforge/base/etc/profile.d/conda.sh" \
    "$HOME/miniconda3/etc/profile.d/conda.sh" \
    "/opt/miniconda3/etc/profile.d/conda.sh" \
    "$HOME/miniforge3/etc/profile.d/conda.sh"; do
    if [ -f "$conda_sh" ]; then
      # shellcheck disable=SC1090
      . "$conda_sh" && break
    fi
  done
fi

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