#!/bin/bash
# @doc
# @name: Error Handling Utilities
# @description: Standardized error handling, logging, and user messaging functions
# @category: Utilities
# @usage: source error_handling.sh
# @requirements: bash shell environment
# @notes: Provides consistent error messages, logging levels, and exit handling across all scripts
# @/doc

# Standard prefix for all Python Support scripts
_prefix="PYS:"

# Error function - Print error message, contact information and exits script
exit_message() {
    echo ""
    echo "Oh no! Something went wrong"
    echo ""
    echo "Please visit the following web page:"
    echo ""
    echo "   https://pythonsupport.dtu.dk/install/macos/automated-error.html"
    echo ""
    echo "or contact the Python Support Team:"
    echo ""
    echo "   pythonsupport@dtu.dk"
    echo ""
    echo "Or visit us during our office hours"
    if [ -z "$PKG_INSTALLER" ]; then
        open https://pythonsupport.dtu.dk/install/macos/automated-error.html
    fi
    exit 1
}

# Logging functions with consistent formatting
log_info() {
    echo "$_prefix $1"
}

log_error() {
    echo "$_prefix ERROR: $1" >&2
}

log_success() {
    echo "$_prefix ✓ $1"
}

log_warning() {
    echo "$_prefix WARNING: $1"
}

log_debug() {
    if [ "$DEBUG" = "true" ]; then
        echo "$_prefix DEBUG: $1" >&2
    fi
}

# Enhanced error checking function
check_exit_code() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        if [ $# -gt 0 ]; then
            log_error "$1"
        fi
        exit_message
    fi
}

# Function to check if a command exists
check_command() {
    local cmd="$1"
    local error_msg="$2"
    
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "${error_msg:-Command '$cmd' not found}"
        exit_message
    fi
}

# Function to require sudo access
require_sudo() {
    local message="$1"
    
    if [ "$EUID" -eq 0 ]; then
        log_warning "Running as root - this may not be necessary"
        return 0
    fi
    
    log_info "${message:-This script requires administrator privileges}"
    if ! sudo -v; then
        log_error "Failed to obtain administrator privileges"
        exit_message
    fi
}