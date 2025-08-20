#!/bin/bash
# @doc
# @name: Piwik Analytics Utility
# @description: Enhanced analytics tracking utility for monitoring installation script usage and success rates with GDPR compliance
# @category: Utilities
# @usage: source piwik_utility.sh; piwik_log "event_name" command args
# @requirements: curl, internet connection
# @notes: Tracks installation events to Piwik PRO for usage analytics and error monitoring with enhanced features and GDPR opt-out support
# @/doc

# Enhanced Piwik PRO Analytics Utility Script
# A utility for tracking installation events with timing, error categorization, environment detection, and GDPR compliance

# === CONFIGURATION ===
PIWIK_URL="https://pythonsupport.piwik.pro/ppms.php"
SITE_ID="0bc7bce7-fb4d-4159-a809-e6bab2b3a431"
GITHUB_REPO="dtudk/pythonsupport-page"

# === GDPR COMPLIANCE ===

# Check if analytics tracking is disabled
is_analytics_disabled() {
    # Check for opt-out file
    local opt_out_file="/tmp/piwik_analytics_choice"
    
    if [ -f "$opt_out_file" ]; then
        local choice=$(cat "$opt_out_file" 2>/dev/null)
        if [ "$choice" = "opt-out" ]; then
            return 0  # Analytics disabled
        elif [ "$choice" = "opt-in" ]; then
            return 1  # Analytics enabled
        fi
    fi
    
    return 1  # Default to enabled if no choice made
}

# Show Apple native popup dialog for analytics choice
show_analytics_choice_dialog() {
    local opt_out_file="/tmp/piwik_analytics_choice"
    
    # Check if choice already exists
    if [ -f "$opt_out_file" ]; then
        return 0  # Choice already made
    fi
    
    # Show Apple native dialog
    local response
    response=$(osascript -e '
        tell application "System Events"
            activate
            set theResponse to display dialog "This installation script collects anonymous usage analytics to help improve the installation process and identify potential issues.

Data collected:
• Installation success/failure events
• Operating system and version information  
• System architecture (Intel/Apple Silicon)
• Installation duration (for performance monitoring)
• Git commit SHA (for version tracking)

No personal information is collected or stored.

Do you consent to analytics collection?" buttons {"Opt Out", "Opt In"} default button "Opt In" with icon note
            return button returned of theResponse
        end tell
    ' 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$response" ]; then
        if [ "$response" = "Opt In" ]; then
            echo "opt-in" > "$opt_out_file"
            echo "✅ Analytics enabled. Thank you for helping improve the installation process!"
        else
            echo "opt-out" > "$opt_out_file"
            echo "❌ Analytics disabled. No data will be collected."
        fi
    else
        # Fallback if osascript fails (non-GUI environment)
        echo "Analytics choice required. Please set your preference:"
        echo "1. Opt in: echo 'opt-in' > /tmp/piwik_analytics_choice"
        echo "2. Opt out: echo 'opt-out' > /tmp/piwik_analytics_choice"
        echo ""
        echo "Do you consent to analytics collection? (y/N): "
        read -r consent
        if [[ "$consent" =~ ^[Yy]$ ]]; then
            echo "opt-in" > "$opt_out_file"
            echo "✅ Analytics enabled. Thank you!"
        else
            echo "opt-out" > "$opt_out_file"
            echo "❌ Analytics disabled."
        fi
    fi
}

# Check and request analytics choice if needed
check_analytics_choice() {
    local opt_out_file="/tmp/piwik_analytics_choice"
    
    if [ ! -f "$opt_out_file" ]; then
        show_analytics_choice_dialog
    fi
}

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
    
    # Enhanced OS and version detection
    if [ "$OS" = "Darwin" ]; then
        # macOS detection
        OS_NAME="macOS"
        
        # Get macOS version and codename
        if command -v sw_vers > /dev/null; then
            OS_VERSION=$(sw_vers -productVersion)
            
            # Map macOS versions to codenames
            case "$OS_VERSION" in
                "15."*)
                    OS_CODENAME="Sequoia"
                    ;;
                "14."*)
                    OS_CODENAME="Sonoma"
                    ;;
                "13."*)
                    OS_CODENAME="Ventura"
                    ;;
                "12."*)
                    OS_CODENAME="Monterey"
                    ;;
                "11."*)
                    OS_CODENAME="Big Sur"
                    ;;
                "10.15"*)
                    OS_CODENAME="Catalina"
                    ;;
                "10.14"*)
                    OS_CODENAME="Mojave"
                    ;;
                "10.13"*)
                    OS_CODENAME="High Sierra"
                    ;;
                "10.12"*)
                    OS_CODENAME="Sierra"
                    ;;
                "10.11"*)
                    OS_CODENAME="El Capitan"
                    ;;
                "10.10"*)
                    OS_CODENAME="Yosemite"
                    ;;
                "10.9"*)
                    OS_CODENAME="Mavericks"
                    ;;
                "10.8"*)
                    OS_CODENAME="Mountain Lion"
                    ;;
                "10.7"*)
                    OS_CODENAME="Lion"
                    ;;
                "10.6"*)
                    OS_CODENAME="Snow Leopard"
                    ;;
                *)
                    OS_CODENAME="Unknown"
                    ;;
            esac
            
            # Combine OS info
            OS="${OS_NAME}${OS_VERSION} (${OS_CODENAME})"
        else
            OS="${OS_NAME} (Unknown Version)"
        fi
        
    elif [ "$OS" = "Linux" ]; then
        # Linux detection
        OS_NAME="Linux"
        
        # Try to get Linux distribution info
        if [ -f /etc/os-release ]; then
            source /etc/os-release
            OS_VERSION="$VERSION"
            OS_CODENAME="$VERSION_CODENAME"
            if [ -n "$OS_CODENAME" ]; then
                OS="${OS_NAME} ${NAME} ${VERSION_ID} (${OS_CODENAME})"
            else
                OS="${OS_NAME} ${NAME} ${VERSION_ID}"
            fi
        elif [ -f /etc/lsb-release ]; then
            source /etc/lsb-release
            OS_VERSION="$DISTRIB_RELEASE"
            OS_CODENAME="$DISTRIB_CODENAME"
            OS="${OS_NAME} ${DISTRIB_DESCRIPTION} (${OS_CODENAME})"
        else
            OS="${OS_NAME} (Unknown Distribution)"
        fi
        
    elif [[ "$OS" == *"NT"* ]] || [[ "$OS" == *"Windows"* ]]; then
        # Windows detection (if running in WSL or similar)
        OS_NAME="Windows"
        
        # Try to get Windows version
        if command -v wmic > /dev/null 2>&1; then
            OS_VERSION=$(wmic os get Caption /value 2>/dev/null | grep "Caption=" | cut -d'=' -f2)
            OS="${OS_NAME} ${OS_VERSION}"
        else
            OS="${OS_NAME} (Unknown Version)"
        fi
        
    else
        # Other Unix-like systems
        OS_NAME="$OS"
        OS_VERSION="Unknown"
        OS="${OS_NAME} (Unknown Version)"
    fi
    
    # Store individual components for potential use
    export OS_NAME
    export OS_VERSION
    export OS_CODENAME
    export OS_ARCH="$ARCH"
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
    # Check analytics choice if needed
    check_analytics_choice
    
    # Check if analytics are disabled
    if is_analytics_disabled; then
        # Run command without tracking
        "$@"
        return $?
    fi
    
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
    # Check analytics choice if needed
    check_analytics_choice
    
    # Check if analytics are disabled
    if is_analytics_disabled; then
        # Run command without tracking
        "$@"
        return $?
    fi
    
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
    
    # Get detailed system information
    get_system_info
    echo "Operating System: $OS_NAME"
    echo "OS Version: $OS_VERSION"
    if [ -n "$OS_CODENAME" ]; then
        echo "OS Codename: $OS_CODENAME"
    fi
    echo "Architecture: $OS_ARCH"
    echo "Full OS String: $OS"
    
    echo "Commit SHA: $(get_commit_sha)"
    
    # Show analytics choice status
    echo "Analytics Choice:"
    local opt_out_file="/tmp/piwik_analytics_choice"
    if [ -f "$opt_out_file" ]; then
        local choice=$(cat "$opt_out_file" 2>/dev/null)
        if [ "$choice" = "opt-out" ]; then
            echo "❌ Analytics disabled (user choice)"
        else
            echo "✅ Analytics enabled (user choice)"
        fi
    else
        echo "⏳ No choice made yet (will prompt on first use)"
    fi
    
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
    # Check analytics choice if needed
    check_analytics_choice
    
    # Check if analytics are disabled
    if is_analytics_disabled; then
        echo "❌ Analytics disabled - cannot test connection"
        return 1
    fi
    
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

# GDPR compliance functions
piwik_opt_out() {
    echo "opt-out" > "/tmp/piwik_analytics_choice"
    echo "✅ Analytics disabled. No data will be collected."
}

piwik_opt_in() {
    echo "opt-in" > "/tmp/piwik_analytics_choice"
    echo "✅ Analytics enabled. Thank you for helping improve the installation process!"
}

piwik_reset_choice() {
    rm -f "/tmp/piwik_analytics_choice"
    echo "✅ Analytics choice reset. You will be prompted again on next use."
}
