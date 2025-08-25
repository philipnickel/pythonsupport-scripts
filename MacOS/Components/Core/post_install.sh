#!/bin/bash
# @doc
# @name: Post-Installation Diagnostics Script
# @description: Runs diagnostics to verify installation and generate report
# @category: Core
# @usage: ./post_install.sh
# @requirements: macOS system, completed installation
# @notes: Runs diagnostics after installation to verify and report results
# @/doc

# Set strict error handling
set -e

# Load utilities
if ! eval "$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared/common.sh")"; then
    echo "ERROR: Failed to load utilities from remote repository"
    exit 1
fi

log "DTU Python Support - Post-Installation Diagnostics"
log "=================================================="

# Run diagnostics and capture exit code
log "Running diagnostic report..."
if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Diagnostics/simple_report.sh)"; then
    exit_code=0
    log "Diagnostic report completed successfully - All tests passed"
else
    exit_code=$?
    log "Diagnostic report completed with exit code: $exit_code"
fi

# Log to Piwik if piwik_utility is available
if command -v piwik_log_event >/dev/null 2>&1; then
    # Log individual test results
    if [ "${PYTHON_INSTALLATION_PASSED:-false}" = "true" ]; then
        piwik_log_event "test_result" "pass" "Python Installation test passed"
        log "Python Installation test: PASS"
    else
        piwik_log_event "test_result" "fail" "Python Installation test failed"
        log "Python Installation test: FAIL"
    fi
    
    if [ "${PYTHON_ENVIRONMENT_PASSED:-false}" = "true" ]; then
        piwik_log_event "test_result" "pass" "Python Environment test passed"
        log "Python Environment test: PASS"
    else
        piwik_log_event "test_result" "fail" "Python Environment test failed"
        log "Python Environment test: FAIL"
    fi
    
    if [ "${VSCODE_SETUP_PASSED:-false}" = "true" ]; then
        piwik_log_event "test_result" "pass" "VS Code Setup test passed"
        log "VS Code Setup test: PASS"
    else
        piwik_log_event "test_result" "fail" "VS Code Setup test failed"
        log "VS Code Setup test: FAIL"
    fi
    
    # Log final overall result
    if [ $exit_code -eq 0 ]; then
        piwik_log_event "post_install_diagnostics" "success" "All tests passed"
        log "All installation tests passed successfully"
    else
        piwik_log_event "post_install_diagnostics" "fail" "Some tests failed"
        log "Some installation tests failed"
    fi
    
    log "Results logged to Piwik analytics"
else
    log "Piwik logging not available"
fi

# Always exit successfully - issues are reported in the diagnostic report
# This ensures the installation process doesn't abort due to diagnostic failures
if [ $exit_code -eq 0 ]; then
    log "Post-installation diagnostics completed successfully"
    exit 0
else
    log "Post-installation diagnostics detected some issues - check the report"
    exit 0
fi