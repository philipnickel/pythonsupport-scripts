#!/bin/bash

# Test script to verify simplified Piwik functionality works correctly
# This script tests the basic piwik logging functionality with consent management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_NAME="Piwik Simplified Functionality Test"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIWIK_UTILITY="$SCRIPT_DIR/../MacOS/Components/Shared/piwik_utility.sh"
TEMP_CHOICE_FILE="/tmp/piwik_analytics_choice"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test results
print_result() {
    local test_name="$1"
    local status="$2"
    local details="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        if [ -n "$details" ]; then
            echo "  Details: $details"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Function to print test section
print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Function to clean up test environment
cleanup_test_env() {
    # Remove any existing choice file
    rm -f "$TEMP_CHOICE_FILE"
    
    # Unset environment variables that might affect tests
    unset PIS_ENV
    unset GITHUB_CI
    unset CI
    unset TESTING_MODE
    unset DEV_MODE
    unset STAGING
    unset DEBUG
}

# Function to test if piwik utility script exists and is executable
test_script_availability() {
    print_section "Script Availability Tests"
    
    if [ -f "$PIWIK_UTILITY" ]; then
        print_result "Piwik utility script exists" "PASS"
    else
        print_result "Piwik utility script exists" "FAIL" "File not found: $PIWIK_UTILITY"
        return 1
    fi
    
    if [ -r "$PIWIK_UTILITY" ]; then
        print_result "Piwik utility script is readable" "PASS"
    else
        print_result "Piwik utility script is readable" "FAIL"
        return 1
    fi
    
    # Test if we can source it without errors
    if source "$PIWIK_UTILITY" 2>/dev/null; then
        print_result "Piwik utility script sources without errors" "PASS"
    else
        print_result "Piwik utility script sources without errors" "FAIL" "Script has syntax errors or missing dependencies"
        return 1
    fi
    
    return 0
}

# Function to test environment detection
test_environment_detection() {
    print_section "Environment Detection Tests"
    
    # Source the script
    source "$PIWIK_UTILITY"
    
    # Test default environment (should be PROD)
    cleanup_test_env
    local env_result=$(detect_environment)
    if [ "$env_result" = "PROD" ]; then
        print_result "Default environment detection" "PASS"
    else
        print_result "Default environment detection" "FAIL" "Expected PROD, got: $env_result"
    fi
    
    # Test CI environment
    export CI="true"
    env_result=$(detect_environment)
    if [ "$env_result" = "CI" ]; then
        print_result "CI environment detection" "PASS"
    else
        print_result "CI environment detection" "FAIL" "Expected CI, got: $env_result"
    fi
    
    # Test DEV environment
    cleanup_test_env
    export DEV_MODE="true"
    env_result=$(detect_environment)
    if [ "$env_result" = "DEV" ]; then
        print_result "DEV environment detection" "PASS"
    else
        print_result "DEV environment detection" "FAIL" "Expected DEV, got: $env_result"
    fi
    
    # Test PIS_ENV override
    cleanup_test_env
    export PIS_ENV="staging"
    env_result=$(detect_environment)
    if [ "$env_result" = "STAGING" ]; then
        print_result "PIS_ENV override detection" "PASS"
    else
        print_result "PIS_ENV override detection" "FAIL" "Expected STAGING, got: $env_result"
    fi
    
    cleanup_test_env
}

# Function to test system information gathering
test_system_info() {
    print_section "System Information Tests"
    
    source "$PIWIK_UTILITY"
    
    # Call get_system_info and check if variables are set
    get_system_info
    
    if [ -n "$OS" ]; then
        print_result "OS variable is set" "PASS"
    else
        print_result "OS variable is set" "FAIL" "OS variable is empty"
    fi
    
    if [ -n "$OS_NAME" ]; then
        print_result "OS_NAME variable is set" "PASS"
    else
        print_result "OS_NAME variable is set" "FAIL" "OS_NAME variable is empty"
    fi
    
    if [ -n "$ARCH" ]; then
        print_result "ARCH variable is set" "PASS"
    else
        print_result "ARCH variable is set" "FAIL" "ARCH variable is empty"
    fi
    
    # Test if OS detection returns reasonable values for macOS
    if [[ "$OS_NAME" == *"macOS"* ]]; then
        print_result "macOS detection works" "PASS"
    else
        print_result "macOS detection works" "FAIL" "Expected macOS in OS_NAME, got: $OS_NAME"
    fi
}

# Function to test commit SHA retrieval
test_commit_sha() {
    print_section "Commit SHA Tests"
    
    source "$PIWIK_UTILITY"
    
    local sha_result=$(get_commit_sha)
    
    if [ -n "$sha_result" ]; then
        print_result "Commit SHA retrieval returns a value" "PASS"
    else
        print_result "Commit SHA retrieval returns a value" "FAIL" "get_commit_sha returned empty"
    fi
    
    # Test if result is either 7-char hex or "unknown"
    if [[ "$sha_result" =~ ^[a-f0-9]{7}$ ]] || [ "$sha_result" = "unknown" ]; then
        print_result "Commit SHA format is valid" "PASS"
    else
        print_result "Commit SHA format is valid" "FAIL" "Expected 7-char hex or 'unknown', got: $sha_result"
    fi
}

# Function to test URI generation
test_uri_generation() {
    print_section "URI Generation Tests"
    
    source "$PIWIK_UTILITY"
    
    local test_value="test-value"
    local uri_result=$(get_uri "$test_value")
    
    if [ -n "$uri_result" ]; then
        print_result "URI generation returns a value" "PASS"
    else
        print_result "URI generation returns a value" "FAIL" "get_uri returned empty"
    fi
    
    # Check if URI contains expected components
    if [[ "$uri_result" == *"pythonsupport.piwik.pro"* ]]; then
        print_result "URI contains correct Piwik URL" "PASS"
    else
        print_result "URI contains correct Piwik URL" "FAIL" "URI doesn't contain expected domain"
    fi
    
    if [[ "$uri_result" == *"e_v=$test_value"* ]]; then
        print_result "URI contains test value parameter" "PASS"
    else
        print_result "URI contains test value parameter" "FAIL" "URI doesn't contain expected test value"
    fi
}

# Function to test analytics choice management
test_analytics_choice() {
    print_section "Analytics Choice Management Tests"
    
    source "$PIWIK_UTILITY"
    cleanup_test_env
    
    # Test initial state (no choice file)
    if is_analytics_disabled; then
        print_result "Initial analytics state is enabled" "FAIL" "Analytics should be enabled by default"
    else
        print_result "Initial analytics state is enabled" "PASS"
    fi
    
    # Test opt-out functionality
    piwik_opt_out > /dev/null 2>&1
    if is_analytics_disabled; then
        print_result "Opt-out functionality works" "PASS"
    else
        print_result "Opt-out functionality works" "FAIL" "Analytics should be disabled after opt-out"
    fi
    
    # Test opt-in functionality
    piwik_opt_in > /dev/null 2>&1
    if is_analytics_disabled; then
        print_result "Opt-in functionality works" "FAIL" "Analytics should be enabled after opt-in"
    else
        print_result "Opt-in functionality works" "PASS"
    fi
    
    # Test choice reset
    piwik_reset_choice > /dev/null 2>&1
    if [ ! -f "$TEMP_CHOICE_FILE" ]; then
        print_result "Choice reset functionality works" "PASS"
    else
        print_result "Choice reset functionality works" "FAIL" "Choice file should be removed after reset"
    fi
    
    # Test CI mode override
    export PIS_ENV="CI"
    piwik_opt_out > /dev/null 2>&1  # Try to opt out
    if is_analytics_disabled; then
        print_result "CI mode overrides opt-out" "FAIL" "Analytics should be enabled in CI mode regardless of choice"
    else
        print_result "CI mode overrides opt-out" "PASS"
    fi
    
    cleanup_test_env
}

# Function to test basic logging functionality
test_basic_logging() {
    print_section "Basic Logging Tests"
    
    source "$PIWIK_UTILITY"
    cleanup_test_env
    
    # Enable analytics for testing
    piwik_opt_in > /dev/null 2>&1
    
    # Test basic logging (this won't actually send to Piwik, just test function execution)
    if piwik_log "test-event" 2>/dev/null; then
        print_result "Basic logging function executes without error" "PASS"
    else
        print_result "Basic logging function executes without error" "FAIL" "piwik_log function returned error"
    fi
    
    # Test logging with analytics disabled
    piwik_opt_out > /dev/null 2>&1
    if piwik_log "test-event" 2>/dev/null; then
        print_result "Logging works when analytics disabled" "PASS"
    else
        print_result "Logging works when analytics disabled" "FAIL" "piwik_log should not fail when analytics disabled"
    fi
    
    cleanup_test_env
}

# Function to test utility functions
test_utility_functions() {
    print_section "Utility Function Tests"
    
    source "$PIWIK_UTILITY"
    
    # Test environment info function
    if piwik_get_environment_info > /dev/null 2>&1; then
        print_result "Environment info function works" "PASS"
    else
        print_result "Environment info function works" "FAIL" "piwik_get_environment_info returned error"
    fi
    
    # Test connection test function (this may fail due to network, but shouldn't crash)
    piwik_opt_in > /dev/null 2>&1  # Enable analytics for test
    local conn_result=0
    piwik_test_connection > /dev/null 2>&1 || conn_result=$?
    
    # We don't fail on connection issues, just that the function runs
    if [ "$conn_result" -eq 0 ] || [ "$conn_result" -eq 1 ]; then
        print_result "Connection test function executes" "PASS"
    else
        print_result "Connection test function executes" "FAIL" "Function crashed with unexpected exit code: $conn_result"
    fi
    
    cleanup_test_env
}

# Main test execution
main() {
    echo -e "${YELLOW}$TEST_NAME${NC}"
    echo "Testing simplified Piwik utility functionality"
    echo "Script location: $PIWIK_UTILITY"
    echo ""
    
    # Run all test suites
    test_script_availability || exit 1
    test_environment_detection
    test_system_info
    test_commit_sha
    test_uri_generation
    test_analytics_choice
    test_basic_logging
    test_utility_functions
    
    # Print final results
    print_section "Test Results Summary"
    echo "Tests run: $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}All tests passed! ✓${NC}"
        exit 0
    else
        echo -e "\n${RED}Some tests failed! ✗${NC}"
        exit 1
    fi
}

# Cleanup function for script exit
cleanup() {
    cleanup_test_env
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"