#!/bin/bash

# Piwik Analytics Test Script
# Simple test that sends different numeric event codes to Piwik

set -e

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIWIK_UTILITY="$SCRIPT_DIR/../MacOS/Components/Shared/piwik_utility.sh"

echo "Piwik Analytics Test"
echo "==================="
echo "Sending test events with different numeric codes..."
echo ""

# Source the piwik utility
source "$PIWIK_UTILITY"

# Send test events with different codes
echo "Sending piwik_log 0 (failure code)..."
piwik_log 0

echo "Sending piwik_log 1 (success code)..."
piwik_log 1

echo "Sending piwik_log 5 (custom code)..."
piwik_log 5

echo "Sending piwik_log 10 (another custom code)..."
piwik_log 10

echo "Sending piwik_log 42 (test code)..."
piwik_log 42

echo "Sending piwik_log 100 (milestone code)..."
piwik_log 100

echo "Sending piwik_log 999 (max test code)..."
piwik_log 999

echo ""
echo "Test complete! Check Piwik dashboard to verify events were received."
echo "Event codes sent: 0, 1, 5, 10, 42, 100, 999"