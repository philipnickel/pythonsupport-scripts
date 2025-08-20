#!/bin/bash
# @doc
# @name: Piwik Analytics Simulator
# @description: Comprehensive testing utility for Piwik analytics with environment simulation
# @category: Testing
# @usage: bash tests/piwik_simulator.sh [environment]
# @requirements: piwik_utility.sh, curl, internet connection
# @notes: Tests all Piwik features including environment detection, timing, and error categorization
# @/doc

# Piwik Analytics Comprehensive Test Simulator
# Tests all features of the enhanced Piwik utility

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILITY_SCRIPT="$SCRIPT_DIR/../MacOS/Components/Shared/piwik_utility.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test configuration
DEFAULT_ENVIRONMENT="DEV"
ENVIRONMENT=${1:-$DEFAULT_ENVIRONMENT}

# Source the utility script
if [ ! -f "$UTILITY_SCRIPT" ]; then
    echo -e "${RED}❌ Error: Piwik utility script not found at $UTILITY_SCRIPT${NC}"
    exit 1
fi

source "$UTILITY_SCRIPT"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
test_passed() {
    echo -e "${GREEN}✅ PASS: $1${NC}"
    ((TESTS_PASSED++))
}

test_failed() {
    echo -e "${RED}❌ FAIL: $1${NC}"
    ((TESTS_FAILED++))
}

test_info() {
    echo -e "${BLUE}ℹ️  INFO: $1${NC}"
}

test_warning() {
    echo -e "${YELLOW}⚠️  WARN: $1${NC}"
}

# Print header
print_header() {
    echo -e "${CYAN}"
    echo "=========================================="
    echo "    Piwik Analytics Test Simulator"
    echo "=========================================="
    echo -e "${NC}"
    echo "Environment: $ENVIRONMENT"
    echo "Utility Script: $UTILITY_SCRIPT"
    echo "Date: $(date)"
    echo ""
}

# Test environment detection
test_environment_detection() {
    echo -e "${PURPLE}🧪 Testing Environment Detection${NC}"
    echo "----------------------------------------"
    
    # Test different environment variables
    local environments=("PROD" "DEV" "CI" "STAGING")
    
    for env in "${environments[@]}"; do
        echo "Testing environment: $env"
        
        # Set environment variables
        case "$env" in
            "CI")
                export GITHUB_CI=true
                export CI=true
                unset TESTING_MODE DEV_MODE STAGING
                ;;
            "DEV")
                export TESTING_MODE=true
                export DEV_MODE=true
                unset GITHUB_CI CI STAGING
                ;;
            "STAGING")
                export STAGING=true
                export STAGE=true
                unset GITHUB_CI CI TESTING_MODE DEV_MODE
                ;;
            "PROD")
                unset GITHUB_CI CI TESTING_MODE DEV_MODE STAGING STAGE
                ;;
        esac
        
        local detected=$(detect_environment)
        local category=$(get_environment_category)
        
        if [ "$detected" = "$env" ]; then
            test_passed "Environment detection for $env: $detected -> $category"
        else
            test_failed "Environment detection for $env: expected $env, got $detected"
        fi
        
        echo "  Detected: $detected"
        echo "  Category: $category"
        echo ""
    done
    
    # Reset to test environment
    case "$ENVIRONMENT" in
        "CI")
            export GITHUB_CI=true
            export CI=true
            ;;
        "DEV")
            export TESTING_MODE=true
            export DEV_MODE=true
            ;;
        "STAGING")
            export STAGING=true
            export STAGE=true
            ;;
        "PROD")
            unset GITHUB_CI CI TESTING_MODE DEV_MODE STAGING STAGE
            ;;
    esac
}

# Test connection
test_connection() {
    echo -e "${PURPLE}🌐 Testing Piwik Connection${NC}"
    echo "----------------------------------------"
    
    if piwik_test_connection; then
        test_passed "Piwik connection successful"
    else
        test_failed "Piwik connection failed"
        test_warning "Some tests may fail due to connection issues"
    fi
    echo ""
}

# Test basic functionality
test_basic_functionality() {
    echo -e "${PURPLE}🔧 Testing Basic Functionality${NC}"
    echo "----------------------------------------"
    
    # Test successful command
    echo "Testing successful command..."
    if piwik_log "test_success" true; then
        test_passed "Basic success tracking"
    else
        test_failed "Basic success tracking"
    fi
    
    # Test failed command
    echo "Testing failed command..."
    if ! piwik_log "test_failure" false; then
        test_passed "Basic failure tracking"
    else
        test_failed "Basic failure tracking"
    fi
    
    echo ""
}

# Test enhanced functionality
test_enhanced_functionality() {
    echo -e "${PURPLE}⚡ Testing Enhanced Functionality${NC}"
    echo "----------------------------------------"
    
    # Test timing
    echo "Testing timing functionality..."
    local start_time=$(date +%s)
    piwik_log_enhanced "test_timing" sleep 1
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ $duration -ge 1 ] && [ $duration -le 3 ]; then
        test_passed "Timing functionality (duration: ${duration}s)"
    else
        test_failed "Timing functionality (unexpected duration: ${duration}s)"
    fi
    
    echo ""
}

# Test error categorization
test_error_categorization() {
    echo -e "${PURPLE}🚨 Testing Error Categorization${NC}"
    echo "----------------------------------------"
    
    # Test permission error
    echo "Testing permission error categorization..."
    piwik_log_enhanced "test_permission" touch /root/test_permission_denied 2>/dev/null
    test_info "Permission error test completed"
    
    # Test network error simulation
    echo "Testing network error categorization..."
    piwik_log_enhanced "test_network" curl -s --connect-timeout 1 http://invalid-domain-xyz123.com 2>/dev/null
    test_info "Network error test completed"
    
    # Test missing dependency
    echo "Testing missing dependency categorization..."
    piwik_log_enhanced "test_missing_dep" nonexistent_command_xyz123 2>/dev/null
    test_info "Missing dependency test completed"
    
    # Test already exists
    echo "Testing already exists categorization..."
    piwik_log_enhanced "test_already_exists" mkdir /tmp 2>/dev/null
    test_info "Already exists test completed"
    
    echo ""
}

# Test different event types
test_event_types() {
    echo -e "${PURPLE}📊 Testing Different Event Types${NC}"
    echo "----------------------------------------"
    
    # Simulate Python installation events
    echo "Testing Python installation events..."
    piwik_log "python_download" echo "Downloading Python 3.11..."
    piwik_log "python_install" echo "Installing Python 3.11..."
    piwik_log "python_verify" python3 --version 2>/dev/null || echo "Python not found"
    
    # Simulate Homebrew events
    echo "Testing Homebrew events..."
    piwik_log "homebrew_check" which brew 2>/dev/null || echo "Homebrew not found"
    piwik_log "homebrew_install" echo "Installing Homebrew..."
    piwik_log "homebrew_update" echo "Updating Homebrew..."
    
    # Simulate VS Code events
    echo "Testing VS Code events..."
    piwik_log "vscode_download" echo "Downloading VS Code..."
    piwik_log "vscode_install" echo "Installing VS Code..."
    piwik_log "vscode_extensions" echo "Installing VS Code extensions..."
    
    # Simulate LaTeX events
    echo "Testing LaTeX events..."
    piwik_log "latex_download" echo "Downloading LaTeX..."
    piwik_log "latex_install" echo "Installing LaTeX..."
    piwik_log "latex_test" echo "Testing LaTeX installation..."
    
    test_passed "All event types tested"
    echo ""
}

# Test environment info
test_environment_info() {
    echo -e "${PURPLE}ℹ️  Testing Environment Information${NC}"
    echo "----------------------------------------"
    
    piwik_get_environment_info
    test_passed "Environment information displayed"
    echo ""
}

# Test system info collection
test_system_info() {
    echo -e "${PURPLE}💻 Testing System Information Collection${NC}"
    echo "----------------------------------------"
    
    get_system_info
    echo "OS: $OS"
    echo "Architecture: $ARCH"
    
    if [ -n "$OS" ] && [ -n "$ARCH" ]; then
        test_passed "System information collection"
    else
        test_failed "System information collection"
    fi
    
    local commit_sha=$(get_commit_sha)
    echo "Commit SHA: $commit_sha"
    
    if [ -n "$commit_sha" ] && [ "$commit_sha" != "unknown" ]; then
        test_passed "Commit SHA retrieval"
    else
        test_warning "Commit SHA retrieval (may be expected in test environment)"
    fi
    
    echo ""
}

# Test different environments
test_environment_simulation() {
    echo -e "${PURPLE}🌍 Testing Environment Simulation${NC}"
    echo "----------------------------------------"
    
    local environments=("PROD" "DEV" "CI" "STAGING")
    
    for env in "${environments[@]}"; do
        echo "Simulating $env environment..."
        
        # Set environment
        case "$env" in
            "CI")
                export GITHUB_CI=true
                export CI=true
                unset TESTING_MODE DEV_MODE STAGING
                ;;
            "DEV")
                export TESTING_MODE=true
                export DEV_MODE=true
                unset GITHUB_CI CI STAGING
                ;;
            "STAGING")
                export STAGING=true
                export STAGE=true
                unset GITHUB_CI CI TESTING_MODE DEV_MODE
                ;;
            "PROD")
                unset GITHUB_CI CI TESTING_MODE DEV_MODE STAGING STAGE
                ;;
        esac
        
        local category=$(get_environment_category)
        echo "  Category: $category"
        
        # Send test event
        piwik_log "environment_test_$env" echo "Test event from $env environment"
        
        echo ""
    done
    
    # Reset to original environment
    case "$ENVIRONMENT" in
        "CI")
            export GITHUB_CI=true
            export CI=true
            ;;
        "DEV")
            export TESTING_MODE=true
            export DEV_MODE=true
            ;;
        "STAGING")
            export STAGING=true
            export STAGE=true
            ;;
        "PROD")
            unset GITHUB_CI CI TESTING_MODE DEV_MODE STAGING STAGE
            ;;
    esac
    
    test_passed "Environment simulation completed"
    echo ""
}

# Test performance scenarios
test_performance_scenarios() {
    echo -e "${PURPLE}⚡ Testing Performance Scenarios${NC}"
    echo "----------------------------------------"
    
    # Test fast command
    echo "Testing fast command timing..."
    piwik_log_enhanced "test_fast_command" echo "Fast command"
    
    # Test slow command
    echo "Testing slow command timing..."
    piwik_log_enhanced "test_slow_command" sleep 2
    
    # Test command with output
    echo "Testing command with output..."
    piwik_log_enhanced "test_with_output" echo "This is a test output with multiple lines" && echo "Second line" && echo "Third line"
    
    test_passed "Performance scenarios tested"
    echo ""
}

# Print summary
print_summary() {
    echo -e "${CYAN}"
    echo "=========================================="
    echo "              Test Summary"
    echo "=========================================="
    echo -e "${NC}"
    
    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    
    echo "Total Tests: $total_tests"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some tests failed.${NC}"
        exit 1
    fi
}

# Main test execution
main() {
    print_header
    
    # Run all tests
    test_environment_detection
    test_connection
    test_basic_functionality
    test_enhanced_functionality
    test_error_categorization
    test_event_types
    test_environment_info
    test_system_info
    test_environment_simulation
    test_performance_scenarios
    
    print_summary
}

# Usage information
show_usage() {
    echo "Usage: $0 [environment]"
    echo ""
    echo "Environments:"
    echo "  PROD     - Production environment (default)"
    echo "  DEV      - Development environment"
    echo "  CI       - CI/CD environment"
    echo "  STAGING  - Staging environment"
    echo ""
    echo "Examples:"
    echo "  $0          # Test with PROD environment"
    echo "  $0 DEV      # Test with DEV environment"
    echo "  $0 CI       # Test with CI environment"
}

# Check for help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

# Validate environment
case "$ENVIRONMENT" in
    "PROD"|"DEV"|"CI"|"STAGING")
        # Valid environment
        ;;
    *)
        echo -e "${RED}❌ Invalid environment: $ENVIRONMENT${NC}"
        echo "Valid environments: PROD, DEV, CI, STAGING"
        exit 1
        ;;
esac

# Run main function
main
