#!/bin/bash
# @doc
# @name: Master Utility Loader
# @description: Loads all Python Support utilities including Piwik analytics
# @category: Utilities
# @usage: source master_utils.sh
# @requirements: bash shell environment, internet connection
# @notes: Sources all utility modules in a single operation
# @/doc

# Master utility loader for Python Support Scripts
# This script loads all utility modules at once

# Standard prefix for all Python Support scripts
_prefix="PYS:"

# Load all utilities at once
load_all_utilities() {
    # Try to load all utilities from the master utilities script
    local master_script
    if master_script=$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-macos-components}/MacOS/Components/Shared/load_utils.sh" 2>/dev/null) && [ -n "$master_script" ]; then
        eval "$master_script"
        echo "$_prefix ✓ Loaded all utilities successfully"
    else
        echo "$_prefix ✗ Failed to load utilities from load_utils.sh"
        echo "$_prefix Falling back to basic functionality..."
        
        # Basic fallback functions
        log_info() { echo "$_prefix $1"; }
        log_error() { echo "$_prefix ERROR: $1" >&2; }
        log_success() { echo "$_prefix ✓ $1"; }
        log_warning() { echo "$_prefix WARNING: $1"; }
        log_debug() {
            if [ "$DEBUG" = "true" ]; then
                echo "$_prefix DEBUG: $1" >&2
            fi
        }
        exit_message() {
            echo "$_prefix Something went wrong. Please contact pythonsupport@dtu.dk"
            exit 1
        }
        check_exit_code() {
            local exit_code=$?
            if [ $exit_code -ne 0 ]; then
                if [ $# -gt 0 ]; then
                    log_error "$1"
                fi
                exit_message
            fi
        }
        ensure_homebrew() {
            if ! command -v brew > /dev/null; then
                log_info "Homebrew is not installed. Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                check_exit_code "Failed to install Homebrew"
                [ -e ~/.bash_profile ] && source ~/.bash_profile
                hash -r
            fi
        }
        # Fallback: define piwik_log as a pass-through function
        piwik_log() {
            shift  # Remove the event name (first argument)
            "$@"   # Execute the actual command
            return $?
        }
    fi
}

# Load all utilities
echo "$_prefix Loading Python Support utilities..."
load_all_utilities

# Set up default environment
set_default_env 2>/dev/null || true
