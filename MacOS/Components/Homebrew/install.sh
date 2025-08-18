#!/bin/bash
# @doc
# @name: Homebrew Installation
# @description: Installs Homebrew package manager on macOS with error handling and user guidance
# @category: Package Manager
# @usage: bash install.sh
# @requirements: macOS system with internet connection
# @notes: Uses shared utilities for consistent error handling and logging
# @/doc

# Load shared utilities
source <(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Shared/load_utils.sh")

# Welcome text 
log_info "Welcome to Python supports MacOS Auto Homebrew Installer Script"
echo ""
log_info "This script will install Homebrew MacOS"
echo ""
log_info "Please do not close the terminal until the installation is complete"
log_info "This might take a while depending on your internet connection and what dependencies needs to be installed"
log_info "The script will take at least 5 minutes to complete depending on your internet connection and computer..."
sleep 3
clear -x

# check for homebrew
echo "Checking for existing Homebrew installation..."

if command -v brew > /dev/null; then
  echo "Already found Homebrew, no need to install Homebrew..."
  exit 0
fi

# First install homebrew 
echo "Installing Homebrew..."
echo ""
echo "This will require you to type your password in the terminal."
echo "For security reasons you will not see what you type... It will be hidden while typing!"
echo ""

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
[ $? -ne 0 ] && exit_message


clear -x 

echo "Setting environment variables..."
# Set environment variables

# Check if brew is in /usr/local/bin/ or /opt/homebrew/bin 
# and set the shellenv accordingly
# as well as add the shellenv to the shell profile

if [ -f /usr/local/bin/brew ]; then
    brew_path=/usr/local/bin/brew
    echo "Brew is installed in /usr/local/bin"
    (echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> ~/.zprofile
    (echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> ~/.bash_profile
elif [ -f /opt/homebrew/bin/brew ]; then
    brew_path=/opt/homebrew/bin/brew
    echo "Brew is installed in /opt/homebrew/bin"
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.bash_profile
else
    echo "Brew is not installed correctly. Exiting"
    exit_message
fi
eval "$($brew_path shellenv)"

clear -x

# update binary locations 
hash -r 

# if homebrew is installed correctly proceed, otherwise exit
if brew help > /dev/null; then
    echo ""
    echo "Installed Homebrew successfully!"
else
    echo "Homebrew installation failed. Exiting..."
    exit_message
fi

