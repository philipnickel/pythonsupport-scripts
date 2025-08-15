#!/bin/bash


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILITY_SCRIPT="$SCRIPT_DIR/piwik_utility.sh"
# Enable testing mode for simulator
export TESTING_MODE=true

# Source the utility script to get the piwik_log function
source "$UTILITY_SCRIPT"

# 2 test cases - success and failure
echo "Starting installation simulations..."
echo
echo "Simulating Python installation success..."
sleep 1
# Simulate a successful command
piwik_log "Python_Installation_Success" true
echo "Python installation completed successfully"
echo

echo "Simulating VS Code installation failure..."
sleep 1
# Generate actual error - command not found
piwik_log "VS_Code_Installation_Failed" nonexistent_command_xyz123
echo "VS Code installation failed (command not found)"
echo

echo "Simulating Python installation with permission error..."
sleep 1
# Generate actual error - permission denied
piwik_log "Python_Installation_Permission_Error" touch /root/test_file_permission_denied
echo "Python installation failed (permission denied)"
echo

echo "=== Usage Examples for Orchestrator Scripts ==="
echo "Ultra-simple usage - just replace commands with piwik_log:"
echo "  piwik_log 'python_installation' python_install_command"
echo "  piwik_log 'vscode_installation' vscode_install_command"
echo "  piwik_log 'homebrew_installation' homebrew_install_command"
echo ""
echo "The function automatically:"
echo "  - Runs the command and captures output"
echo "  - Detects success/failure from exit status"
echo "  - Sets event value (1=success, 0=failure)"
echo "  - Sends system info and commit SHA"
echo "  - Includes error messages when failures occur"
echo "  - Returns the original command's exit code"
echo "  - Sets event category based on environment variables:"
echo "    * Local: 'Installer' (default)"
echo "    * Testing: 'Installer_TEST' (when TESTING_MODE=true)"
echo "    * CI: 'Installer_CI' (when GITHUB_CI=true)"
echo ""
echo "Environment Variables:"
echo "  export TESTING_MODE=true    # For testing/development"
echo "  export GITHUB_CI=true       # For GitHub workflows"
echo

