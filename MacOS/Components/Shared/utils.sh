#!/bin/bash
# @doc
# @name: Shared Utilities
# @description: Common utility functions used across all Python Support installation scripts
# @category: Utilities
# @usage: source utils.sh
# @requirements: bash shell environment
# @notes: Provides error handling, logging, and common functionality for all components
# @/doc

# Shared utility functions for Python Support Scripts

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
        BRANCH_PS="macos-components"
    fi
    
    export REMOTE_PS
    export BRANCH_PS
}

# Function to get the base URL for scripts
get_base_url() {
    set_default_env
    echo "https://raw.githubusercontent.com/$REMOTE_PS/$BRANCH_PS/MacOS"
}

# Standard prefix for all Python Support scripts
_prefix="PYS:"

# Logging functions
log_info() {
    echo "$_prefix $1"
}

log_error() {
    echo "$_prefix ERROR: $1" >&2
}

log_success() {
    echo "$_prefix ✓ $1"
}

# Enhanced error checking function
check_exit_code() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        if [ $# -gt 0 ]; then
            log_error "$1"
        fi
        exit_message
    fi
}

# Function to source a remote script safely
source_remote_script() {
    local script_url="$1"
    local script_name="$2"
    
    log_info "Sourcing remote script: $script_name"
    local script_content
    if script_content=$(curl -fsSL "$script_url" 2>/dev/null) && [ -n "$script_content" ]; then
        eval "$script_content"
        log_success "Successfully sourced $script_name"
    else
        log_error "Failed to source remote script: $script_name"
        exit_message
    fi
}

# Function to ensure conda environment is available
ensure_conda_available() {
    # Source shell profiles to make conda available
    [ -e ~/.bashrc ] && source ~/.bashrc 2>/dev/null || true
    [ -e ~/.bash_profile ] && source ~/.bash_profile 2>/dev/null || true  
    [ -e ~/.zshrc ] && source ~/.zshrc 2>/dev/null || true
    
    # Add miniforge to PATH if it exists
    if [ -d "$HOME/miniforge3/bin" ]; then
        export PATH="$HOME/miniforge3/bin:$PATH"
    fi
    
    # Update PATH hash
    hash -r
    
    if command -v conda >/dev/null 2>&1; then
        log_info "Conda is available"
        return 0
    else
        log_info "Conda not found in PATH"
        return 1
    fi
}

# Function to setup conda environment
ensure_conda_env() {
    if command -v conda >/dev/null 2>&1; then
        log_info "Setting up conda environment..."
        eval "$(conda shell.bash hook)" 2>/dev/null || true
        conda activate base 2>/dev/null || true
    else
        log_info "Conda not available - some functionality may be limited"
    fi
}