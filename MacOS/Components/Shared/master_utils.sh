#!/bin/bash
# @doc
# @name: Master Utility Loader
# @description: Loads all Python Support utilities including Piwik analytics
# @category: Utilities
# @usage: source master_utils.sh
# @requirements: bash shell environment, internet connection
# @notes: Sources error_handling, environment, dependencies, remote_utils, and piwik_utility modules
# @/doc

# Master utility loader for Python Support Scripts
# This script loads all utility modules in the correct order

# Standard prefix for all Python Support scripts
_prefix="PYS:"

# Function to safely source a utility script
load_utility() {
    local util_name="$1"
    # Use the same approach as Piwik utility loading
    local util_script
    if util_script=$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-macos-components}/MacOS/Components/Shared/${util_name}.sh" 2>/dev/null) && [ -n "$util_script" ]; then
        eval "$util_script"
        echo "$_prefix ✓ Loaded $util_name utilities"
    else
        echo "$_prefix ✗ Failed to load $util_name utilities"
        echo "$_prefix Falling back to basic functionality..."
        
        # Basic fallback functions
        if [ "$util_name" = "error_handling" ]; then
            log_info() { echo "$_prefix $1"; }
            log_error() { echo "$_prefix ERROR: $1" >&2; }
            log_success() { echo "$_prefix ✓ $1"; }
            log_warning() { echo "$_prefix WARNING: $1"; }
            exit_message() {
                echo "$_prefix Something went wrong. Please contact pythonsupport@dtu.dk"
                exit 1
            }
        elif [ "$util_name" = "piwik_utility" ]; then
            # Fallback: define piwik_log as a pass-through function
            piwik_log() {
                shift  # Remove the event name (first argument)
                "$@"   # Execute the actual command
                return $?
            }
        fi
    fi
}

# Load utilities in dependency order
echo "$_prefix Loading Python Support utilities..."

# 1. Load error handling first (needed by others)
load_utility "error_handling"

# 2. Load environment setup
load_utility "environment"

# 3. Load dependency management
load_utility "dependencies" 

# 4. Load remote utilities
load_utility "remote_utils"

# 5. Load Piwik analytics
load_utility "piwik_utility"

echo "$_prefix ✓ All utilities loaded successfully"

# Set up default environment
set_default_env 2>/dev/null || true
