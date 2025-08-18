#!/bin/bash
# @doc
# @name: Homebrew Installation
# @description: Installs Homebrew package manager on macOS with error handling and user guidance
# @category: Package Manager
# @usage: bash install.sh
# @requirements: macOS system with internet connection
# @notes: Uses master utility system for consistent error handling and logging
# @/doc

# Load master utilities
source <(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-macos-components}/MacOS/Components/Shared/master_utils.sh")

# Welcome text 
log_info "Welcome to Python supports MacOS Auto Homebrew Installer Script"
log_info "This script will install Homebrew MacOS"
log_info "Please do not close the terminal until the installation is complete"
log_info "This might take a while depending on your internet connection and what dependencies needs to be installed"
log_info "The script will take at least 5 minutes to complete depending on your internet connection and computer..."
sleep 3
clear -x

# check for homebrew
log_info "Checking for existing Homebrew installation..."

if command -v brew > /dev/null; then
  log_success "Already found Homebrew, no need to install Homebrew..."
  exit 0
fi

# First install homebrew 
log_info "Installing Homebrew..."
log_info "This will require you to type your password in the terminal."
log_info "For security reasons you will not see what you type... It will be hidden while typing!"

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
check_exit_code "Failed to install Homebrew"

clear -x 

log_info "Setting environment variables..."

# Check if brew is in /usr/local/bin/ or /opt/homebrew/bin 
# and set the shellenv accordingly
# as well as add the shellenv to the shell profile

if [ -f /usr/local/bin/brew ]; then
    brew_path=/usr/local/bin/brew
    log_info "Brew is installed in /usr/local/bin"
    (echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> ~/.zprofile
    (echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> ~/.bash_profile
elif [ -f /opt/homebrew/bin/brew ]; then
    brew_path=/opt/homebrew/bin/brew
    log_info "Brew is installed in /opt/homebrew/bin"
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.bash_profile
else
    log_error "Brew is not installed correctly"
    exit_message
fi
eval "$($brew_path shellenv)"

clear -x

# update binary locations 
hash -r 

# if homebrew is installed correctly proceed, otherwise exit
if brew help > /dev/null; then
    log_success "Installed Homebrew successfully!"
else
    log_error "Homebrew installation failed"
    exit_message
fi

