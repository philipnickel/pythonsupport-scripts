#!/bin/bash

# Shared utility functions for Python Support Scripts
# Copyright 2023 - The Technical University of Denmark

# Error function 
# Print error message, contact information and exits script
exit_message() {
    echo ""
    echo "Oh no! Something went wrong"
    echo ""
    echo "Please visit the following web page:"
    echo ""
    echo "   https://pythonsupport.dtu.dk/install/macos/automated-error.html"
    echo ""
    echo "or contact the Python Support Team:"
    echo ""
    echo "   pythonsupport@dtu.dk"
    echo ""
    echo "Or visit us during our office hours"
    open https://pythonsupport.dtu.dk/install/macos/automated-error.html
    exit 1
}

# Function to set default environment variables
set_default_env() {
    if [ -z "$REMOTE_PS" ]; then
        REMOTE_PS="dtudk/pythonsupport-scripts"
    fi
    if [ -z "$BRANCH_PS" ]; then
        BRANCH_PS="main"
    fi
    
    export REMOTE_PS
    export BRANCH_PS
}

# Function to get the base URL for scripts
get_base_url() {
    set_default_env
    echo "https://raw.githubusercontent.com/$REMOTE_PS/$BRANCH_PS/MacOS"
}

# Function to check and install Homebrew if needed
ensure_homebrew() {
    local _prefix="$1"
    local url_ps="$2"
    
    if ! command -v brew > /dev/null; then
        echo "$_prefix Homebrew is not installed. Installing Homebrew..."
        echo "$_prefix Installing from $url_ps/Components/Homebrew/install.sh"
        /bin/bash -c "$(curl -fsSL $url_ps/Components/Homebrew/install.sh)"

        # The above will install everything in a subshell.
        # So just to be sure we have it on the path
        [ -e ~/.bash_profile ] && source ~/.bash_profile

        # update binary locations 
        hash -r
    fi
}