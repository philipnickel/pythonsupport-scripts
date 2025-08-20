#!/bin/bash
# @doc
# @name: Piwik Analytics Example Usage
# @description: Example script demonstrating enhanced Piwik utility usage
# @category: Examples
# @usage: bash tests/piwik_example.sh [environment]
# @requirements: piwik_utility.sh, curl, internet connection
# @notes: Shows how to integrate Piwik tracking into installation scripts
# @/doc

# Example script demonstrating enhanced Piwik utility usage
# This shows how to integrate Piwik tracking into real installation scenarios

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILITY_SCRIPT="$SCRIPT_DIR/../MacOS/Components/Shared/piwik_utility.sh"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Environment setup
ENVIRONMENT=${1:-"DEV"}

# Set environment variables based on argument
case "$ENVIRONMENT" in
    "CI")
        export GITHUB_CI=true
        export CI=true
        echo -e "${BLUE}Running in CI environment${NC}"
        ;;
    "DEV")
        export TESTING_MODE=true
        export DEV_MODE=true
        echo -e "${BLUE}Running in DEV environment${NC}"
        ;;
    "STAGING")
        export STAGING=true
        export STAGE=true
        echo -e "${BLUE}Running in STAGING environment${NC}"
        ;;
    "PROD")
        unset GITHUB_CI CI TESTING_MODE DEV_MODE STAGING STAGE
        echo -e "${BLUE}Running in PROD environment${NC}"
        ;;
    *)
        echo -e "${YELLOW}Invalid environment: $ENVIRONMENT. Using DEV.${NC}"
        export TESTING_MODE=true
        export DEV_MODE=true
        ;;
esac

# Source the Piwik utility
if [ ! -f "$UTILITY_SCRIPT" ]; then
    echo -e "${YELLOW}❌ Piwik utility not found. Creating fallback function.${NC}"
    # Fallback piwik_log function
    piwik_log() {
        local event_name="$1"
        shift
        echo -e "${GREEN}📊 Piwik Event: $event_name${NC}"
        "$@"
    }
    piwik_log_enhanced() {
        piwik_log "$@"
    }
else
    source "$UTILITY_SCRIPT"
    echo -e "${GREEN}✅ Piwik utility loaded${NC}"
fi

echo ""
echo "=== Piwik Analytics Example ==="
echo "This script demonstrates how to use the enhanced Piwik utility"
echo ""

# Show environment information
echo -e "${BLUE}Environment Information:${NC}"
piwik_get_environment_info
echo ""

# Example 1: Basic usage
echo -e "${BLUE}Example 1: Basic Piwik Logging${NC}"
echo "----------------------------------------"
piwik_log "example_basic_success" echo "This is a successful command"
piwik_log "example_basic_failure" false
echo ""

# Example 2: Enhanced usage with timing
echo -e "${BLUE}Example 2: Enhanced Logging with Timing${NC}"
echo "----------------------------------------"
piwik_log_enhanced "example_enhanced_success" echo "This command will be timed"
piwik_log_enhanced "example_enhanced_sleep" sleep 1
echo ""

# Example 3: Python installation simulation
echo -e "${BLUE}Example 3: Python Installation Simulation${NC}"
echo "----------------------------------------"
echo "Simulating Python installation process..."

# Check if Python is already installed
piwik_log "python_check_installed" python3 --version 2>/dev/null || echo "Python not found"

# Simulate download
piwik_log "python_download" echo "Downloading Python 3.11.0..."

# Simulate installation
piwik_log "python_install" echo "Installing Python 3.11.0..."

# Verify installation
piwik_log "python_verify" python3 --version 2>/dev/null || echo "Python installation failed"

echo ""

# Example 4: Homebrew installation simulation
echo -e "${BLUE}Example 4: Homebrew Installation Simulation${NC}"
echo "----------------------------------------"
echo "Simulating Homebrew installation process..."

# Check if Homebrew is installed
piwik_log "homebrew_check_installed" which brew 2>/dev/null || echo "Homebrew not found"

# Simulate Homebrew installation
piwik_log "homebrew_install" echo "Installing Homebrew..."

# Simulate Homebrew update
piwik_log "homebrew_update" echo "Updating Homebrew..."

echo ""

# Example 5: VS Code installation simulation
echo -e "${BLUE}Example 5: VS Code Installation Simulation${NC}"
echo "----------------------------------------"
echo "Simulating VS Code installation process..."

# Simulate VS Code download
piwik_log "vscode_download" echo "Downloading Visual Studio Code..."

# Simulate VS Code installation
piwik_log "vscode_install" echo "Installing Visual Studio Code..."

# Simulate extension installation
piwik_log "vscode_extensions_install" echo "Installing VS Code extensions..."

echo ""

# Example 6: Error handling demonstration
echo -e "${BLUE}Example 6: Error Handling Demonstration${NC}"
echo "----------------------------------------"
echo "Demonstrating error categorization..."

# Permission error
piwik_log_enhanced "example_permission_error" touch /root/test_file 2>/dev/null

# Network error
piwik_log_enhanced "example_network_error" curl -s --connect-timeout 1 http://invalid-domain-xyz123.com 2>/dev/null

# Missing dependency
piwik_log_enhanced "example_missing_dependency" nonexistent_command_xyz123 2>/dev/null

echo ""

# Example 7: Performance monitoring
echo -e "${BLUE}Example 7: Performance Monitoring${NC}"
echo "----------------------------------------"
echo "Demonstrating performance tracking..."

# Fast command
piwik_log_enhanced "example_fast_command" echo "Fast command execution"

# Slow command
piwik_log_enhanced "example_slow_command" sleep 2

# Command with output
piwik_log_enhanced "example_command_with_output" echo "Line 1" && echo "Line 2" && echo "Line 3"

echo ""

# Example 8: Real installation script integration
echo -e "${BLUE}Example 8: Real Installation Script Integration${NC}"
echo "----------------------------------------"
echo "This is how you would integrate Piwik into a real installation script:"

cat << 'EOF'
#!/bin/bash
# Example installation script with Piwik tracking

# Source the Piwik utility
source "MacOS/Components/Shared/piwik_utility.sh"

# Set environment (this would be set by your CI/CD or deployment process)
export TESTING_MODE=true  # or GITHUB_CI=true for CI

# Installation process with tracking
echo "Starting installation..."

# Check system requirements
piwik_log "system_check" check_system_requirements

# Download components
piwik_log "component_download" download_components

# Install components
piwik_log "component_install" install_components

# Verify installation
piwik_log "installation_verify" verify_installation

# Post-installation setup
piwik_log "post_install_setup" setup_post_installation

echo "Installation completed!"
EOF

echo ""
echo -e "${GREEN}✅ Example completed!${NC}"
echo ""
echo -e "${YELLOW}Note: All events have been sent to Piwik with the following information:${NC}"
echo "  - Environment: $(detect_environment)"
echo "  - Category: $(get_environment_category)"
get_system_info
echo "  - Operating System: $OS_NAME"
echo "  - OS Version: $OS_VERSION"
if [ -n "$OS_CODENAME" ]; then
    echo "  - OS Codename: $OS_CODENAME"
fi
echo "  - Architecture: $OS_ARCH"
echo "  - Commit SHA: $(get_commit_sha)"
echo ""
echo -e "${BLUE}Analytics Choice Information:${NC}"
local opt_out_file="/tmp/piwik_analytics_choice"
if [ -f "$opt_out_file" ]; then
    local choice=$(cat "$opt_out_file" 2>/dev/null)
    if [ "$choice" = "opt-out" ]; then
        echo "❌ Analytics disabled (user choice)"
    else
        echo "✅ Analytics enabled (user choice)"
    fi
else
    echo "⏳ No choice made yet (will prompt on first use)"
fi
echo ""
echo "To opt out of analytics:"
echo "  echo 'opt-out' > /tmp/piwik_analytics_choice"
echo "  piwik_opt_out"
echo ""
echo "To opt back in:"
echo "  echo 'opt-in' > /tmp/piwik_analytics_choice"
echo "  piwik_opt_in"
echo ""
echo "To reset choice (will prompt again):"
echo "  piwik_reset_choice"
echo ""
echo -e "${BLUE}You can view these events in your Piwik PRO dashboard.${NC}"
