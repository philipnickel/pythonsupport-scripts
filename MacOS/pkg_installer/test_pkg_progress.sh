#!/bin/bash

# Test script for PKG installer progress system
# This demonstrates the improved progress logging that appears in installer logs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/src/Scripts/loading_animations.sh"

echo ""
echo "Testing PKG Installer Progress System"
echo "====================================="
echo ""
echo "This test shows how progress will appear in the macOS Installer log."
echo "During real PKG installation, press ⌘L to view these messages."
echo ""

# Test installer header
show_installer_header

# Test system checks (like preinstall)
show_progress_log "Starting pre-installation system checks..." "INFO"
show_progress_log "✓ macOS version: $(sw_vers -productVersion)" "INFO"
show_progress_log "✓ Sufficient disk space available" "INFO"
show_progress_log "✓ Administrator privileges confirmed" "INFO"
show_progress_log "🎯 All pre-installation checks passed - ready to begin installation!" "INFO"

sleep 2

# Test installation steps (like postinstall)
show_progress_log "Starting DTU Python installation (estimated 10-15 minutes)..." "INFO"

# Test component installations with progress bars
show_progress_step "1" "6" "Installing Homebrew package manager" "2-3 min"
show_component_progress "Homebrew" "starting"
sleep 1
show_component_progress "Homebrew" "progress" "Downloading and installing Homebrew..."
sleep 1
show_component_progress "Homebrew" "completed"

show_progress_step "2" "6" "Installing Python via Miniconda" "5-8 min"
show_component_progress "Python" "starting"
sleep 1
show_component_progress "Python" "progress" "Downloading Miniconda installer..."
sleep 1
show_component_progress "Python" "progress" "Installing Python environment..."
sleep 1
show_component_progress "Python" "completed"

show_progress_step "3" "6" "Installing Visual Studio Code" "1-2 min"
show_component_progress "Visual Studio Code" "starting"
sleep 1
show_component_progress "Visual Studio Code" "completed"

show_progress_step "4" "6" "Configuring Python environment" "1-2 min"
show_component_progress "Python Environment" "starting"
sleep 1
show_component_progress "Python Environment" "completed"

show_progress_step "5" "6" "Running installation diagnostics" "30 sec"
show_component_progress "Installation Diagnostics" "starting"
sleep 1
show_component_progress "Installation Diagnostics" "completed"

show_progress_step "6" "6" "Cleaning up installation files" "5 sec"
show_component_progress "Cleanup" "starting"
sleep 1
show_component_progress "Cleanup" "completed"

# Test installation summary
show_installation_summary "Homebrew, Python, VS Code, Development packages" "3m 45s"

echo ""
echo "✅ PKG Progress System Test Complete!"
echo ""
echo "During real PKG installation:"
echo "1. These messages will appear in the installer log (press ⌘L in Installer.app)"
echo "2. Users can select 'Show All Logs' for complete details"
echo "3. Progress bars and status messages help track installation progress"
echo "4. Final notification will appear after installer closes"
echo ""

# Test completion notification (this would appear after PKG installer closes)
echo "Testing post-installation notification (would appear after installer closes)..."
show_completion_notification "true" "DTU Python Installation Complete!\\n\\nYour development environment is ready to use.\\n\\nNext steps:\\n• Open Terminal and type 'python3'\\n• Launch Visual Studio Code\\n\\nInstallation completed in 3m 45s"