#!/bin/bash

# Test script for loading animations
# Run this to test the animation functions before building the PKG

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/src/Scripts/loading_animations.sh"

echo "Testing DTU Python PKG Installer Loading Animations"
echo "===================================================="
echo ""

echo "1. Testing welcome dialog..."
show_welcome_dialog
sleep 2

echo "2. Testing progress notification..."
show_progress_notification "Testing notifications" "This is a test"
sleep 2

echo "3. Testing loading dialog..."
show_loading_dialog "Testing basic loading dialog..." 3
sleep 1

echo "4. Testing step dialog..."
show_step_dialog "1" "3" "Testing step 1 of 3"
sleep 3

echo "5. Testing completion dialog (success)..."
show_completion_dialog "true" "Test completed successfully!\\n\\nAll loading animations are working properly."
sleep 2

echo "6. Testing animated loading sequence..."
echo "   (This will show 6 progress dots over 15 seconds)"
ANIMATION_PID=$(show_animated_loading "Testing animated loading..." 15 6)
sleep 16
kill "$ANIMATION_PID" 2>/dev/null || true

echo "7. Final cleanup..."
cleanup_loading_dialogs

echo ""
echo "✅ Loading animation test completed!"
echo "All dialogs and notifications should have appeared during the test."
echo "If you saw the dialogs, the animations are working correctly."