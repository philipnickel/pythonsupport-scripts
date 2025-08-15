#!/bin/bash


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILITY_SCRIPT="$SCRIPT_DIR/piwik_utility.sh"
# Enable testing mode for simulator
export TESTING_MODE=true

# Source the utility script to get the piwik_log function
source "$UTILITY_SCRIPT"

# 5 different log calls - ultra simple one-liners
echo "Starting installation simulations..."
echo
echo "Simulating Python installation start..."
sleep 1
piwik_log "Python_Installation_Start"
echo "Python installation started"
echo

echo "Simulating Python installation success..."
sleep 1
piwik_log "Python_Installation_Success"
echo "Python installation completed successfully"
echo

echo "Simulating VS Code installation failure..."
sleep 1
piwik_log "VS_Code_Installation_Failed" "network_error"
echo "VS Code installation failed (network error)"
echo

echo "Simulating Homebrew installation success..."
sleep 1
piwik_log "Homebrew_Installation_Success"
echo "Homebrew installation completed successfully"
echo

echo "Simulating LaTeX installation cancellation..."
sleep 1
piwik_log "LaTeX_Installation_Cancelled" "user_cancelled"
echo "LaTeX installation was cancelled by user"
echo
