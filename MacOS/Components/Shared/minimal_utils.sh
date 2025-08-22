#!/bin/bash
# Minimal utilities for component scripts
# Provides essential functionality without bloat

# Exit codes for consistent component behavior
readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1  
readonly EXIT_ALREADY_INSTALLED=10

# Installation method detection
readonly INSTALL_METHOD="${PIS_INSTALL_METHOD:-CLI}"

# Base URLs for remote resources
readonly REMOTE_PS="${REMOTE_PS:-dtudk/pythonsupport-scripts}"
readonly BRANCH_PS="${BRANCH_PS:-main}"
readonly BASE_URL="https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared"

# Load essential utilities
load_utilities() {
    # Load piwik analytics
    if ! declare -f piwik_log >/dev/null 2>&1; then
        eval "$(curl -fsSL "$BASE_URL/piwik_utility.sh" 2>/dev/null)" || true
    fi
}

# Clean output suitable for both CLI and PKG logs
output() {
    local level="$1"
    local message="$2"
    local component="${3:-}"
    
    case "$level" in
        "success")
            echo "✓ ${component}${component:+ }${message}"
            ;;
        "info")
            echo "${component}${component:+ }${message}"
            ;;
        "error")
            echo "✗ ${component}${component:+ }${message}"
            ;;
        "skip")
            echo "✓ ${component}${component:+ }${message} (already installed)"
            ;;
    esac
}

# Check if command exists and is functional
is_installed() {
    local command="$1"
    local test_command="${2:-$1 --version}"
    
    command -v "$command" >/dev/null 2>&1 && eval "$test_command" >/dev/null 2>&1
}

# Graceful exit with analytics
exit_with_status() {
    local exit_code="$1"
    local component="$2"
    local status="$3"
    
    # Track analytics
    if declare -f piwik_log >/dev/null 2>&1; then
        # Convert to lowercase (compatible with older bash)
        local method_lower=$(echo "$INSTALL_METHOD" | tr '[:upper:]' '[:lower:]')
        piwik_log "${component}_${method_lower}_${status}"
    fi
    
    exit "$exit_code"
}

# Initialize utilities when sourced
load_utilities