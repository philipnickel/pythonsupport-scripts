#!/bin/bash
# @doc
# @name: Piwik Analytics Utility
# @description: Analytics tracking utility for monitoring installation script usage with GDPR compliance
# @category: Utilities
# @usage: source piwik_utility.sh; piwik_log "event_name"
# @requirements: curl, internet connection
# @notes: Tracks installation events to Piwik PRO for usage analytics with GDPR opt-out support
# @/doc

# Piwik PRO Analytics Utility Script
# A utility for tracking installation events with GDPR compliance

# === CONFIGURATION ===
PIWIK_URL="https://pythonsupport.piwik.pro/ppms.php"
SITE_ID="0bc7bce7-fb4d-4159-a809-e6bab2b3a431"
GITHUB_REPO="dtudk/pythonsupport-page"
CATEGORY="AUTOINSTALLS"
EVENT_ACTION="Event"
EVENT_NAME="Log"

# === GDPR COMPLIANCE ===

is_analytics_disabled() {
    # In CI mode, always enable analytics
    if [ "$PIS_ENV" = "CI" ]; then
        return 1  # Analytics enabled in CI
    fi
    
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

Do you consent to analytics collection?" buttons {"Decline tracking", "Accept tracking"} default button "Accept tracking" with icon note
            return button returned of theResponse
        end tell
    ' 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$response" ]; then
        if [ "$response" = "Accept tracking" ]; then
            echo "opt-in" > "$opt_out_file"
            echo "Analytics enabled. Thank you for helping improve the installation process!"
        else
            echo "opt-out" > "$opt_out_file"
            echo "Analytics disabled. No data will be collected."
        fi
    else
        # Fallback if osascript fails (non-GUI environment) - default to not tracking
        echo "opt-out" > "$opt_out_file"
        echo "Analytics disabled (non-GUI environment)."
    fi
}

check_analytics_choice() {
    # In CI mode, skip dialog and enable analytics
    if [ "$PIS_ENV" = "CI" ]; then
        return 0  # Skip dialog in CI
    fi
    
    local opt_out_file="/tmp/piwik_analytics_choice"
    
    if [ ! -f "$opt_out_file" ]; then
        show_analytics_choice_dialog
    fi
}

# === ENVIRONMENT DETECTION ===

detect_environment() {
    if [ -n "$PIS_ENV" ]; then
        case "$PIS_ENV" in
            "CI") echo "CI" ;;
            "local-dev") echo "DEV" ;;
            "staging") echo "STAGING" ;;
            "production") echo "PROD" ;;
            *) echo "PROD" ;;
        esac
        return 0
    fi
    
    if [ "$GITHUB_CI" = "true" ] || [ "$CI" = "true" ] || [ "$TRAVIS" = "true" ] || [ "$CIRCLECI" = "true" ]; then
        echo "CI"
    elif [ "$TESTING_MODE" = "true" ] || [ "$DEV_MODE" = "true" ] || [ "$DEBUG" = "true" ]; then
        echo "DEV"
    elif [ "$STAGING" = "true" ] || [ "$STAGE" = "true" ]; then
        echo "STAGING"
    else
        echo "PROD"
    fi
}

# === HELPER FUNCTIONS ===

get_system_info() {
    local os_name="macOS"
    local os_ver=$(sw_vers -productVersion 2>/dev/null || echo "Unknown")
    local os_code=$(sw_vers -productName 2>/dev/null || echo "macOS")
    local arch=$(uname -m)
    
    OS="$os_name $os_ver ($os_code)"
    OS_NAME="$os_name"
    OS_VERSION="$os_ver"
    OS_CODENAME="$os_code"
    ARCH="$arch"
}

get_commit_sha() {
    local response
    response=$(curl -s --connect-timeout 5 --max-time 10 \
        "https://api.github.com/repos/$GITHUB_REPO/commits/main" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$response" ]; then
        local sha=$(echo "$response" | sed -n 's/.*"sha": *"\([a-f0-9]*\)".*/\1/p' | head -c 7)
        if echo "$sha" | grep -qE '^[a-f0-9]{7}$'; then
            echo "$sha"
            return 0
        fi
    fi
    
    echo "unknown"
}

get_uri() {
    local value="$1"
    get_system_info
    local commit_sha=$(get_commit_sha)
    
    # URL encode the OS string to handle spaces and special characters
    local encoded_os=$(printf '%s' "$OS" | sed 's/ /%20/g' | sed 's/(/%28/g' | sed 's/)/%29/g')
    
    # Add timestamp to make events more identifiable
    local timestamp=$(date +%s)
    
    echo "${PIWIK_URL}?idsite=${SITE_ID}&rec=1&e_c=${CATEGORY}&e_a=${EVENT_ACTION}&e_n=${EVENT_NAME}_${value}&e_v=${value}&dimension1=${encoded_os}&dimension2=${ARCH}&dimension3=${commit_sha}&cdt=${timestamp}"
}

# === LOGGING FUNCTIONS ===

piwik_log() {
    local value="$1"  # Numeric event value (0=failure, 1=success, etc.)
    
    check_analytics_choice
    if is_analytics_disabled; then
        return 0
    fi
    
    local uri=$(get_uri "$value")
    
    # Send request to Piwik
    curl -s "$uri" > /dev/null 2>&1 || true
}

# === UTILITY FUNCTIONS ===

piwik_get_environment_info() {
    echo "=== Piwik Environment Information ==="
    local env_type=$(detect_environment)
    echo "Detected Environment: $env_type"
    echo "Piwik Category: $CATEGORY"
    
    get_system_info
    echo "Operating System: $OS_NAME"
    echo "OS Version: $OS_VERSION"
    if [ -n "$OS_CODENAME" ]; then
        echo "OS Codename: $OS_CODENAME"
    fi
    echo "Architecture: $ARCH"
    echo "Full OS String: $OS"
    echo "Commit SHA: $(get_commit_sha)"
    
    echo "Analytics Choice:"
    if [ "$PIS_ENV" = "CI" ]; then
        echo "Analytics enabled (CI mode - automatic)"
    else
        local opt_out_file="/tmp/piwik_analytics_choice"
        if [ -f "$opt_out_file" ]; then
            local choice=$(cat "$opt_out_file" 2>/dev/null)
            if [ "$choice" = "opt-out" ]; then
                echo "Analytics disabled (user choice)"
            else
                echo "Analytics enabled (user choice)"
            fi
        else
            echo "No choice made yet (will prompt on first use)"
        fi
    fi
    
    echo "Environment Variables:"
    echo "  PIS_ENV: ${PIS_ENV:-not set}"
    echo "  GITHUB_CI: ${GITHUB_CI:-not set}"
    echo "  CI: ${CI:-not set}"
    echo "  TESTING_MODE: ${TESTING_MODE:-not set}"
    echo "  DEV_MODE: ${DEV_MODE:-not set}"
    echo "  STAGING: ${STAGING:-not set}"
    echo "  DEBUG: ${DEBUG:-not set}"
    echo "================================"
}

piwik_test_connection() {
    check_analytics_choice
    if is_analytics_disabled; then
        echo "Analytics disabled - cannot test connection"
        return 1
    fi
    
    echo "Testing Piwik connection..."
    local uri=$(get_uri "test-con")
    local test_response
    test_response=$(curl -s -w "%{http_code}" -o /dev/null "$uri" 2>/dev/null)
    
    if [ "$test_response" = "200" ] || [ "$test_response" = "202" ]; then
        echo "Piwik connection successful (HTTP $test_response)"
        return 0
    else
        echo "Piwik connection failed (HTTP $test_response)"
        return 1
    fi
}

piwik_opt_out() {
    echo "opt-out" > "/tmp/piwik_analytics_choice"
    echo "Analytics disabled. No data will be collected."
}

piwik_opt_in() {
    echo "opt-in" > "/tmp/piwik_analytics_choice"
    echo "Analytics enabled. Thank you for helping improve the installation process!"
}

piwik_reset_choice() {
    rm -f "/tmp/piwik_analytics_choice"
    echo "Analytics choice reset. You will be prompted again on next use."
}