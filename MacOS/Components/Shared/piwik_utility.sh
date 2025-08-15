#!/bin/bash

# Piwik PRO Analytics Utility Script
# A comprehensive utility for tracking installation events
# Copyright 2024 DTU Python Support Team

# === CONFIGURATION ===
PIWIK_URL="https://pythonsupport.piwik.pro/ppms.php"
SITE_ID="0bc7bce7-fb4d-4159-a809-e6bab2b3a431"
SCRIPT_VERSION="1.0.0"

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

# Main tracking function - ultra simple one-line interface
piwik_log() {
    local event="$1"
    local result="${2:-success}"
    

    
    get_system_info
    
    # Set event category based on TESTING mode
    local event_category="Installer"
    if [ "$TESTING_MODE" = "true" ]; then
        event_category="Installer_TEST"
    fi
    
    # Send request and capture HTTP status code
    HTTP_CODE=$(curl -s -w "%{http_code}" -G "$PIWIK_URL" \
        --max-time 10 \
        --connect-timeout 5 \
        --data-urlencode "idsite=$SITE_ID" \
        --data-urlencode "rec=1" \
        --data-urlencode "e_c=$event_category" \
        --data-urlencode "e_a=Event" \
        --data-urlencode "e_n=$event" \
        --data-urlencode "e_v=0" \
        --data-urlencode "dimension1=$OS" \
        --data-urlencode "dimension2=$ARCH" \
        --data-urlencode "dimension3=$SCRIPT_VERSION" 2>/dev/null)
    
    # Return success/failure based on HTTP code
    if [ "$HTTP_CODE" = "202" ] || [ "$HTTP_CODE" = "200" ]; then
        return 0
    else
        return 1
    fi
}
