#!/bin/bash

# DTU Python Installation Script (PKG Installer)
# This script calls the actual first_year_students.sh orchestrator

LOG_FILE="PLACEHOLDER_LOG_FILE"
# Redirect output to both log file and stdout so installer can see progress
exec > >(tee -a "$LOG_FILE") 2>&1

echo "$(date): DEBUG: PKG installer calling first_year_students.sh orchestrator"

# Determine user and set environment
USER_NAME=$(stat -f%Su /dev/console)
export USER="$USER_NAME"
export HOME="/Users/$USER_NAME"

# Set up the same environment variables as the orchestrator
export REMOTE_PS="PLACEHOLDER_REPO"
export BRANCH_PS="PLACEHOLDER_BRANCH"

echo "$(date): DEBUG: User=$USER_NAME, Home=$HOME"
echo "$(date): DEBUG: Remote=$REMOTE_PS, Branch=$BRANCH_PS"

# Load loading animation functions for progress display
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/loading_animations.sh" 2>/dev/null || {
    # Define minimal fallback functions
    show_progress_log() { echo "$(date '+%H:%M:%S') [${2:-INFO}] DTU Python Installer: $1"; }
    show_installer_header() { echo "=== DTU Python Installation ==="; }
}

show_installer_header
show_progress_log "Starting first year students installation..." "INFO"

echo "$(date): DEBUG: About to test curl access to GitHub"
curl_test_url="https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/orchestrators/first_year_students.sh"
echo "$(date): DEBUG: Testing URL: $curl_test_url"

# Test curl access first
if curl -fsSL --connect-timeout 10 "$curl_test_url" | head -5; then
    echo "$(date): DEBUG: Curl test successful"
else
    echo "$(date): DEBUG: Curl test failed with exit code: $?"
    exit 1
fi

echo "$(date): DEBUG: About to call actual orchestrator script"

# Call the actual first_year_students.sh orchestrator
show_progress_log "Calling first_year_students.sh orchestrator..." "INFO"
if sudo -u "$USER_NAME" env HOME="/Users/$USER_NAME" REMOTE_PS="$REMOTE_PS" BRANCH_PS="$BRANCH_PS" PIS_ENV="CI" GITHUB_CI="true" CI="true" GITHUB_ACTIONS="true" RUNNER_OS="macOS" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/orchestrators/first_year_students.sh)"; then
    orchestrator_ret=0
    echo "$(date): DEBUG: Orchestrator completed successfully"
    show_progress_log "🎉 First year students orchestrator completed successfully!" "INFO"
else
    orchestrator_ret=$?
    echo "$(date): DEBUG: Orchestrator failed with exit code: $orchestrator_ret"
    show_progress_log "❌ First year students orchestrator failed" "ERROR"
fi

# Create summary
SUMMARY_FILE="PLACEHOLDER_SUMMARY_FILE"
cat > "$SUMMARY_FILE" << EOF
DTU First Year Students Installation Complete!

Installation log: $LOG_FILE
Date: $(date)
User: $USER_NAME

Installation Results:
- First Year Students Orchestrator: $([ $orchestrator_ret -eq 0 ] && echo "SUCCESS" || echo "FAILED")

Next steps:
1. Open Terminal and type 'python3' to test Python
2. Open Visual Studio Code to start coding
3. Try importing: dtumathtools, pandas, numpy, matplotlib

For support: PLACEHOLDER_SUPPORT_EMAIL
EOF

show_progress_log "PKG installer script has finished. Summary created at: $SUMMARY_FILE" "INFO"
echo "$(date): DEBUG: PKG installer script finished"

exit $orchestrator_ret