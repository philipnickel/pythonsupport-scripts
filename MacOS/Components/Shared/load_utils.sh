#!/bin/bash
# @doc
# @name: Utility Loader
# @description: Master loader that sources all Python Support utility modules
# @category: Utilities
# @usage: source load_utils.sh
# @requirements: bash shell environment, internet connection
# @notes: Automatically loads error_handling, environment, dependencies, and remote_utils modules
# @/doc

# Master utility loader for Python Support Scripts
# This script loads all utility modules in the correct order

# Determine the base URL for utilities
if [ -z "$REMOTE_PS" ]; then
    REMOTE_PS="dtudk/pythonsupport-scripts"
fi
if [ -z "$BRANCH_PS" ]; then
    BRANCH_PS="macos-components"
fi

BASE_UTIL_URL="https://raw.githubusercontent.com/$REMOTE_PS/$BRANCH_PS/MacOS/Components/Shared"

# Function to safely source a utility script
load_utility() {
    local util_name="$1"
    local util_url="$BASE_UTIL_URL/$util_name.sh"
    
    if util_content=$(curl -fsSL "$util_url" 2>/dev/null) && [ -n "$util_content" ]; then
        eval "$util_content"
        echo "✓ Loaded $util_name utilities"
    else
        echo "✗ Failed to load $util_name utilities from $util_url"
        echo "Falling back to basic functionality..."
        
        # Basic fallback functions
        if [ "$util_name" = "error_handling" ]; then
            _prefix="PYS:"
            log_info() { echo "$_prefix $1"; }
            log_error() { echo "$_prefix ERROR: $1" >&2; }
            log_success() { echo "$_prefix ✓ $1"; }
            exit_message() {
                echo "$_prefix Something went wrong. Please contact pythonsupport@dtu.dk"
                exit 1
            }
        fi
    fi
}

# Load utilities in dependency order
echo "Loading Python Support utilities..."

# 1. Load error handling first (needed by others)
load_utility "error_handling"

# 2. Load environment setup
load_utility "environment"

# 3. Load dependency management
load_utility "dependencies" 

# 4. Load remote utilities
load_utility "remote_utils"

echo "✓ All utilities loaded successfully"

# Set up default environment
set_default_env 2>/dev/null || true