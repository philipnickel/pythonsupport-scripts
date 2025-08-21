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

# Set defaults only if environment variables are not already set
if [ -z "$REMOTE_PS" ]; then
    REMOTE_PS="dtudk/pythonsupport-scripts"
fi
if [ -z "$BRANCH_PS" ]; then
    BRANCH_PS="main"
fi

# Function to safely source a utility script
load_utility() {
    local util_name="$1"
    local util_script

    # When running from a packaged installer, load utilities from local disk
    if [ "${REMOTE_PS}" = "local-pkg" ] || [ "${BRANCH_PS}" = "local-pkg" ]; then
        local local_path="/usr/local/share/dtu-pythonsupport/Components/Shared/${util_name}.sh"
        if [ -f "$local_path" ]; then
            # shellcheck disable=SC1090
            . "$local_path"
            echo "$_prefix ✓ Loaded $util_name utilities (local)"
            return 0
        fi
        echo "$_prefix ✗ Local utility not found: $local_path"
        return 1
    fi

    # Default: fetch utilities from remote repository
    if util_script=$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared/${util_name}.sh" 2>/dev/null) && [ -n "$util_script" ]; then
        eval "$util_script"
        echo "$_prefix ✓ Loaded $util_name utilities"
    else
        echo "$_prefix ✗ Failed to load $util_name utilities"
    fi
}

# Load all utilities at once
load_all_utilities() {
    echo "$_prefix Loading Python Support utilities from ${REMOTE_PS}/${BRANCH_PS}..."
    
    # Load utilities in dependency order
    load_utility "error_handling"
    load_utility "environment"
    load_utility "dependencies"
    load_utility "remote_utils"
    load_utility "piwik_utility"
    
    echo "$_prefix ✓ All utilities loaded successfully"
}

# Load all utilities
load_all_utilities

# Set up default environment
set_default_env 2>/dev/null || true
