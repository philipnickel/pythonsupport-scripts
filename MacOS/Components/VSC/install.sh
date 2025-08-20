#!/bin/bash
# @doc
# @name: VSCode Installation
# @description: Installs Visual Studio Code on macOS with Python extension setup
# @category: IDE
# @usage: bash install.sh
# @requirements: macOS system, Homebrew (for cask installation)
# @notes: Uses shared utilities for consistent error handling and logging. Configures remote repository settings and installs via Homebrew cask
# @/doc

# Load shared utilities
source <(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Shared/load_utils.sh")

log_info "Installing Visual Studio Code"

# Check for homebrew and install if needed
ensure_homebrew

# check if vs code is installed
# using multipleVersions script to check 
log_info "Installing Visual Studio Code if not already installed..."
# if output is empty, then install vs code
vspath=$(/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/VSC/multipleVersions.sh)")
check_exit_code "Failed to check VSCode installation status"

if [ -n "$vspath" ]  ; then
    log_success "Visual Studio Code is already installed"
else
    log_info "Installing Visual Studio Code"
    brew install --cask visual-studio-code
    check_exit_code "Failed to install Visual Studio Code"
fi

hash -r
clear -x

log_info "Setting up Visual Studio Code environment..."
eval "$(brew shellenv)"

# Test if code is installed correctly
if code --version > /dev/null; then
    log_success "Visual Studio Code installed successfully"
else
    log_error "Visual Studio Code installation failed"
    exit_message
fi

log_success "Visual Studio Code installation completed!"