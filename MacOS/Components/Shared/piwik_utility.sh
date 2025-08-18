#!/bin/bash

# Piwik PRO Analytics Utility Script
# A utility for tracking installation events

# === CONFIGURATION ===
PIWIK_URL="https://pythonsupport.piwik.pro/ppms.php"
SITE_ID="0bc7bce7-fb4d-4159-a809-e6bab2b3a431"
GITHUB_REPO="dtudk/pythonsupport-page"

# === HELPER FUNCTIONS ===

# Get system information
get_system_info() {
    OS=$(uname -s)
    ARCH=$(uname -m)
    
    # Get macOS version if available
    if command -v sw_vers > /dev/null; then
        OS_VERSION=$(sw_vers -productVersion)
        OS="${OS}${OS_VERSION}"
    fi
}

# Get latest commit SHA from GitHub
get_commit_sha() {
    local sha
    sha=$(curl -s \
        -H "Accept: application/vnd.github.VERSION.sha" \
        "https://api.github.com/repos/$GITHUB_REPO/commits/main" 2>/dev/null | head -c 7)
    
    # Return the short SHA or a fallback
    if [ -n "$sha" ] && [ "$sha" != "Not Found" ]; then
        echo "$sha"
    else
        echo "unknown"
    fi
}



# Main tracking function - runs command and tracks result automatically
piwik_log() {
    local event_name="$1"
    shift  # Remove first argument, leaving the command
    
    # Run the command and capture both stdout and stderr
    local output
    output=$("$@" 2>&1)
    local exit_code=$?
    
    # Display the output (both stdout and stderr)
    echo "$output"
    
    get_system_info
    
    # Get the latest commit SHA
    local commit_sha=$(get_commit_sha)
    
    # Set event category based on environment variables
    local event_category="Installer"
    
    if [ "$TESTING_MODE" = "true" ]; then
        event_category="Installer_TEST"
    elif [ "$GITHUB_CI" = "true" ]; then
        event_category="Installer_CI"
    fi
    
    # Determine result and value based on exit status
    local result="success"
    local event_value="1"
    
    if [ $exit_code -ne 0 ]; then
        result="failure"
        event_value="0"
    fi
    
    # Send request and capture HTTP status code, discard response body
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -G "$PIWIK_URL" \
        --max-time 10 \
        --connect-timeout 5 \
        --data-urlencode "idsite=$SITE_ID" \
        --data-urlencode "rec=1" \
        --data-urlencode "e_c=$event_category" \
        --data-urlencode "e_a=Event" \
        --data-urlencode "e_n=$event_name" \
        --data-urlencode "e_v=$event_value" \
        --data-urlencode "dimension1=$OS" \
        --data-urlencode "dimension2=$ARCH" \
        --data-urlencode "dimension3=$commit_sha" 2>/dev/null)
    
    # Return the original command's exit code
    return $exit_code
}
