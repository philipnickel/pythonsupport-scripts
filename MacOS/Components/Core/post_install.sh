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

REMOTE_PS=${REMOTE_PS:-"dtudk/pythonsupport-scripts"}
BRANCH_PS=${BRANCH_PS:-"main"}

# Load Piwik utility for analytics
#if curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared/piwik_utility.sh" -o /tmp/piwik_utility.sh 2>/dev/null && source /tmp/piwik_utility.sh 2>/dev/null; then
#    PIWIK_LOADED=true
#else
#    PIWIK_LOADED=false
#fi

# Source shell profile to ensure conda is available in PATH for diagnostics
echo "Refreshing shell environment for diagnostics..."
source ~/.zshrc 2>/dev/null || source ~/.bash_profile 2>/dev/null || source ~/.bashrc 2>/dev/null || true

# Run diagnostics and capture exit code
if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Diagnostics/simple_report.sh)"; then
    exit_code=0
else
    exit_code=$?
fi

# Log script completion to Piwik if available
#[ "$PIWIK_LOADED" = true ] && piwik_log 99  # Script Finished

# Clean up Piwik choice file so users get consent dialog again on next run
#rm -f /tmp/piwik_analytics_choice

# Always exit successfully - issues are reported in the diagnostic report
# This ensures the installation process doesn't abort due to diagnostic failures
if [ $exit_code -eq 0 ]; then
    exit 0
else
    exit 0
fi