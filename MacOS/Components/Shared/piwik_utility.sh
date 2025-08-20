#!/bin/bash
# @doc
# @name: Piwik Analytics Utility
# @description: Enhanced analytics tracking utility for monitoring installation script usage and success rates
# @category: Utilities
# @usage: source piwik_utility.sh; piwik_log "event_name" command args
# @requirements: curl, internet connection
# @notes: Tracks installation events to Piwik PRO for usage analytics and error monitoring with enhanced features
# @/doc

# Enhanced Piwik PRO Analytics Utility Script
# A utility for tracking installation events with timing, error categorization, and environment detection

# === CONFIGURATION ===
PIWIK_URL="https://pythonsupport.piwik.pro/ppms.php"
SITE_ID="0bc7bce7-fb4d-4159-a809-e6bab2b3a431"
GITHUB_REPO="dtudk/pythonsupport-page"

# === ENVIRONMENT DETECTION ===

# Detect environment automatically
detect_environment() {
    # Check for CI environment first
    if [ "$GITHUB_CI" = "true" ] || [ "$CI" = "true" ] || [ "$TRAVIS" = "true" ] || [ "$CIRCLECI" = "true" ]; then
        echo "CI"
        return 0
    fi
    
    # Check for testing/development environment
    if [ "$TESTING_MODE" = "true" ] || [ "$DEV_MODE" = "true" ] || [ "$DEBUG" = "true" ]; then
        echo "DEV"
        return 0
    fi
    
    # Check for staging environment
    if [ "$STAGING" = "true" ] || [ "$STAGE" = "true" ]; then
        echo "STAGING"
        return 0
    fi
    
    # Default to production
    echo "PROD"
    return 0
}

# Get environment category for Piwik
get_environment_category() {
    local env=$(detect_environment)
    case "$env" in
        "CI")
            echo "Installer_CI"
            ;;
        "DEV")
            echo "Installer_DEV"
            ;;
        "STAGING")
            echo "Installer_STAGING"
            ;;
        "PROD")
            echo "Installer_PROD"
            ;;
        *)
            echo "Installer_UNKNOWN"
            ;;
    esac
}

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
    local response
    
    # Try to get the SHA from GitHub API
    response=$(curl -s --connect-timeout 5 --max-time 10 \
        -H "Accept: application/vnd.github.v3.sha" \
        "https://api.github.com/repos/$GITHUB_REPO/commits/main" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$response" ]; then
        sha=$(echo "$response" | head -c 7)
        
        # Check if we got a valid SHA (7 hex characters)
        if echo "$sha" | grep -qE '^[a-f0-9]{7}$'; then
            echo "$sha"
            return 0
        fi
    fi
    
    # Fallback: try without custom header (gets JSON, extract sha field)
    response=$(curl -s --connect-timeout 5 --max-time 10 \
        "https://api.github.com/repos/$GITHUB_REPO/commits/main" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$response" ]; then
        sha=$(echo "$response" | sed -n 's/.*"sha": *"\([a-f0-9]*\)".*/\1/p' | head -c 7)
        if echo "$sha" | grep -qE '^[a-f0-9]{7}$'; then
            echo "$sha"
            return 0
        fi
    fi
    
    echo "unknown"
}

# Categorize error types
categorize_error() {
    local output="$1"
    local exit_code="$2"
    
    if [ "$exit_code" -eq 0 ]; then
        echo ""
        return 0
    fi
    
    # Check for common error patterns
    if echo "$output" | grep -iq "permission denied\|not permitted\|access denied"; then
        echo "_permission_error"
    elif echo "$output" | grep -iq "network\|download\|curl\|wget\|connection\|timeout"; then
        echo "_network_error"
    elif echo "$output" | grep -iq "space\|disk\|storage\|no space"; then
        echo "_disk_error"
    elif echo "$output" | grep -iq "not found\|command not found\|no such file"; then
        echo "_missing_dependency"
    elif echo "$output" | grep -iq "already exists\|already installed"; then
        echo "_already_exists"
    elif echo "$output" | grep -iq "version\|incompatible\|requires"; then
        echo "_version_error"
    else
        echo "_unknown_error"
    fi
}

# === ENHANCED TRACKING FUNCTIONS ===

# Enhanced logging function with timing and error categorization
piwik_log_enhanced() {
    local event_name="$1"
    local start_time=$(date +%s)
    shift
    
    # Run command and capture output
    local output
    output=$("$@" 2>&1)
    local exit_code=$?
    local duration=$(($(date +%s) - start_time))
    
    # Display output
    echo "$output"
    
    # Enhance event name for failures
    local error_suffix=$(categorize_error "$output" "$exit_code")
    if [ -n "$error_suffix" ]; then
        event_name="${event_name}${error_suffix}"
    fi
    
    get_system_info
    local commit_sha=$(get_commit_sha)
    local event_category=$(get_environment_category)
    
    # Set result and use duration as event value for successes
    local result="success"
    local event_value="$duration"
    
    if [ $exit_code -ne 0 ]; then
        result="failure"
        event_value="0"
    fi
    
    # Send to Piwik with enhanced info
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
    
    return $exit_code
}

# Original piwik_log function (backwards compatibility)
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
    
    # Get environment category
    local event_category=$(get_environment_category)
    
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

# Convenience wrapper - uses enhanced version if available
piwik_log_timed() {
    piwik_log_enhanced "$@"
}

# === UTILITY FUNCTIONS ===

# Get current environment info
piwik_get_environment_info() {
    echo "=== Piwik Environment Information ==="
    echo "Detected Environment: $(detect_environment)"
    echo "Piwik Category: $(get_environment_category)"
    echo "System Info: $(get_system_info)"
    echo "Commit SHA: $(get_commit_sha)"
    echo "Environment Variables:"
    echo "  GITHUB_CI: ${GITHUB_CI:-not set}"
    echo "  CI: ${CI:-not set}"
    echo "  TESTING_MODE: ${TESTING_MODE:-not set}"
    echo "  DEV_MODE: ${DEV_MODE:-not set}"
    echo "  STAGING: ${STAGING:-not set}"
    echo "  DEBUG: ${DEBUG:-not set}"
    echo "================================"
}

# Test Piwik connection
piwik_test_connection() {
    echo "Testing Piwik connection..."
    local test_response
    test_response=$(curl -s -w "%{http_code}" -o /dev/null -G "$PIWIK_URL" \
        --max-time 10 \
        --connect-timeout 5 \
        --data-urlencode "idsite=$SITE_ID" \
        --data-urlencode "rec=1" \
        --data-urlencode "e_c=Installer_TEST" \
        --data-urlencode "e_a=Event" \
        --data-urlencode "e_n=connection_test" \
        --data-urlencode "e_v=1" 2>/dev/null)
    
    # Piwik PRO returns 202 for successful tracking requests
    if [ "$test_response" = "200" ] || [ "$test_response" = "202" ]; then
        echo "✅ Piwik connection successful (HTTP $test_response)"
        return 0
    else
        echo "❌ Piwik connection failed (HTTP $test_response)"
        return 1
    fi
}
