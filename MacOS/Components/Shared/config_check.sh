#!/bin/bash
# Main Controller Check Utility
# Verifies if component is enabled via main_controller.md
# Usage: check_component_enabled "component_name" || exit 1

check_component_enabled() {
    local component_name="$1"
    local platform="${2:-macOS}"  # Default to macOS
    local controller_url="https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/main_controller.md"
    
    # Fetch main controller with fallback
    local controller_content
    if ! controller_content=$(curl -fsSL "$controller_url" 2>/dev/null); then
        # If controller fetch fails, allow execution (fail-open for reliability)
        return 0
    fi
    
    # Check maintenance mode first
    if echo "$controller_content" | grep -q "Maintenance Mode.*\*\*Enabled\*\*"; then
        echo "WARNING: System is currently under maintenance"
        echo "         Please check the repository for updates and try again later."
        return 1
    fi
    
    # Parse markdown table to check if component is enabled
    local component_line
    case "$component_name" in
        "orchestrator")
            component_line=$(echo "$controller_content" | grep -i "orchestrator")
            ;;
        "legacy")
            component_line=$(echo "$controller_content" | grep -i "legacy")
            ;;
        "pkg")
            component_line=$(echo "$controller_content" | grep -i "pkg\|installer")
            ;;
        *)
            # Unknown component, allow by default
            return 0
            ;;
    esac
    
    # Check if component is disabled (contains "Disabled")
    if echo "$component_line" | grep -q "\*\*Disabled\*\*"; then
        echo "WARNING: $component_name installation is currently disabled"
        echo "         This component has been temporarily disabled by administrators."
        echo "         Check main_controller.md for current status."
        return 1
    fi
    
    return 0
}

# Export function for use in other scripts
export -f check_component_enabled