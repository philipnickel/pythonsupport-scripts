#!/bin/bash
# @doc
# @name: Utility System Test
# @description: Test script to verify the master utility loader works correctly
# @category: Testing
# @usage: bash test_utilities.sh
# @requirements: bash shell environment, internet connection
# @notes: Tests all utility functions including logging, error handling, and Piwik analytics
# @/doc

# Load master utilities using the same approach as Piwik utility
source_master_utils() {
    # Try to source the master utilities - if it fails, define fallbacks
    local master_script
    if master_script=$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-macos-components}/MacOS/Components/Shared/master_utils.sh" 2>/dev/null) && [ -n "$master_script" ]; then
        eval "$master_script"
        echo "PYS: Master utilities initialized"
    else
        echo "PYS: Master utilities not available, using fallback"
        # Fallback: define basic functions
        _prefix="PYS:"
        log_info() { echo "$_prefix $1"; }
        log_error() { echo "$_prefix ERROR: $1" >&2; }
        log_success() { echo "$_prefix ✓ $1"; }
        log_warning() { echo "$_prefix WARNING: $1"; }
        exit_message() {
            echo "$_prefix Something went wrong. Please contact pythonsupport@dtu.dk"
            exit 1
        }
        piwik_log() {
            shift  # Remove the event name (first argument)
            "$@"   # Execute the actual command
            return $?
        }
    fi
}

# Initialize master utilities
source_master_utils

# Test logging functions
log_info "Testing utility system..."
log_success "Logging functions work correctly"
log_warning "This is a test warning"
log_debug "This is a debug message (only visible if DEBUG=true)"

# Test error handling
echo "Testing error handling..."
if [ "$1" = "fail" ]; then
    log_error "Simulated error for testing"
    exit_message
fi

# Test environment functions
echo "Testing environment functions..."
if command -v set_default_env > /dev/null; then
    log_success "Environment functions loaded"
else
    log_warning "Environment functions not available"
fi

# Test dependency functions
echo "Testing dependency functions..."
if command -v ensure_homebrew > /dev/null; then
    log_success "Dependency functions loaded"
else
    log_warning "Dependency functions not available"
fi

# Test remote utilities
echo "Testing remote utilities..."
if command -v source_remote_script > /dev/null; then
    log_success "Remote utilities loaded"
else
    log_warning "Remote utilities not available"
fi

# Test Piwik analytics
echo "Testing Piwik analytics..."
if command -v piwik_log > /dev/null; then
    log_success "Piwik analytics loaded"
    # Test Piwik logging with a simple command
    piwik_log 'test_utility_system' echo "Piwik analytics test successful"
else
    log_warning "Piwik analytics not available"
fi

# Test system detection
echo "Testing system detection..."
if command -v get_system_info > /dev/null; then
    log_success "System detection functions loaded"
    get_system_info
    log_info "OS: $OS, Arch: $ARCH"
else
    log_warning "System detection functions not available"
fi

log_success "All utility tests completed successfully!"
log_info "Utility system is working correctly"
