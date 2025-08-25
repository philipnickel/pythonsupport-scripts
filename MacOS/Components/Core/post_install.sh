#!/bin/bash
# @doc
# @name: Post-Installation Diagnostics Script
# @description: Runs diagnostics to verify installation and generate report
# @category: Core
# @usage: ./post_install.sh
# @requirements: macOS system, completed installation
# @notes: Runs diagnostics after installation to verify and report results
# @/doc

# Allow scripts to continue on errors for complete diagnostics

# Note: Utilities loading removed to ensure script runs without external dependencies


# Run diagnostics and capture exit code
if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Diagnostics/simple_report.sh)"; then
    exit_code=0
else
    exit_code=$?
fi

# Log to Piwik if piwik_utility is available
if command -v piwik_log_event >/dev/null 2>&1; then
    # Log individual test results
    if [ "${PYTHON_INSTALLATION_PASSED:-false}" = "true" ]; then
        piwik_log_event "test_result" "pass" "Python Installation test passed"
    else
        piwik_log_event "test_result" "fail" "Python Installation test failed"
    fi
    
    if [ "${PYTHON_ENVIRONMENT_PASSED:-false}" = "true" ]; then
        piwik_log_event "test_result" "pass" "Python Environment test passed"
    else
        piwik_log_event "test_result" "fail" "Python Environment test failed"
    fi
    
    if [ "${VSCODE_SETUP_PASSED:-false}" = "true" ]; then
        piwik_log_event "test_result" "pass" "VS Code Setup test passed"
    else
        piwik_log_event "test_result" "fail" "VS Code Setup test failed"
    fi
    
    # Log final overall result
    if [ $exit_code -eq 0 ]; then
        piwik_log_event "post_install_diagnostics" "success" "All tests passed"
    else
        piwik_log_event "post_install_diagnostics" "fail" "Some tests failed"
    fi
fi

# Always exit successfully - issues are reported in the diagnostic report
# This ensures the installation process doesn't abort due to diagnostic failures
if [ $exit_code -eq 0 ]; then
    exit 0
else
    exit 0
fi