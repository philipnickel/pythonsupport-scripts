#!/bin/bash
# @doc
# @name: Environment Setup Utilities
# @description: Environment variable management and system configuration functions
# @category: Utilities
# @usage: source environment.sh
# @requirements: bash shell environment
# @notes: Handles REMOTE_PS/BRANCH_PS variables, URL construction, and environment validation
# @/doc

# Function to set default environment variables for remote repository access
set_default_env() {
    if [ -z "$REMOTE_PS" ]; then
        REMOTE_PS="dtudk/pythonsupport-scripts"
    fi
    if [ -z "$BRANCH_PS" ]; then
        BRANCH_PS="main"
    fi
    if [ -z "$PYTHON_VERSION_PS" ]; then
        PYTHON_VERSION_PS="3.11"
    fi
    
    export REMOTE_PS
    export BRANCH_PS
    export PYTHON_VERSION_PS
}

# Function to get the base URL for scripts
get_base_url() {
    set_default_env
    echo "https://raw.githubusercontent.com/$REMOTE_PS/$BRANCH_PS/MacOS"
}

# Function to construct component script URLs
get_script_url() {
    local component="$1"
    local script="$2"
    local base_url=$(get_base_url)
    echo "$base_url/Components/$component/$script"
}

# Function to detect system architecture
get_system_arch() {
    uname -m
}

# Function to detect macOS version
get_macos_version() {
    sw_vers -productVersion
}

# Function to check system requirements
check_system_requirements() {
    local min_macos="${1:-10.15}"
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only"
        exit_message
    fi
    
    # Check macOS version
    local current_version=$(get_macos_version)
    if ! version_greater_equal "$current_version" "$min_macos"; then
        log_error "macOS $min_macos or later is required (current: $current_version)"
        exit_message
    fi
    
    log_info "System check passed: macOS $current_version ($(get_system_arch))"
}

# Function to compare version numbers
version_greater_equal() {
    local version1="$1"
    local version2="$2"
    
    # Use sort -V to compare version numbers
    local higher=$(printf '%s\n%s\n' "$version1" "$version2" | sort -V | tail -n1)
    [ "$higher" = "$version1" ]
}

# Function to setup shell environment
setup_shell_env() {
    local shell_rc=""
    
    # Determine shell configuration file
    case "$SHELL" in
        */bash) shell_rc="$HOME/.bashrc" ;;
        */zsh) shell_rc="$HOME/.zshrc" ;;
        *) shell_rc="$HOME/.profile" ;;
    esac
    
    # Ensure the file exists
    touch "$shell_rc"
    echo "$shell_rc"
}