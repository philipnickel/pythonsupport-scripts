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

# Log script completion to Piwik if available
if command -v piwik_log >/dev/null 2>&1; then
    piwik_log 99  # Script Finished
fi

# Always exit successfully - issues are reported in the diagnostic report
# This ensures the installation process doesn't abort due to diagnostic failures
if [ $exit_code -eq 0 ]; then
    exit 0
else
    exit 0
fi