#!/bin/bash
# Main Controller Check Utility
# Verifies if component is enabled via main_controller.txt
# Usage: check_component_enabled "component_name" || exit 1

check_component_enabled() {
    local component_name="$1"
    local controller_url="https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/main_controller.txt"
    
    # Fetch main controller with fallback
    local controller_content
    if ! controller_content=$(curl -fsSL "$controller_url" 2>/dev/null); then
        # If controller fetch fails, allow execution (fail-open for reliability)
        return 0
    fi
    
    # Simple grep for component=disabled
    if echo "$controller_content" | grep -q "^${component_name}=disabled"; then
        echo "WARNING: $component_name installation is currently disabled"
        echo "         This component has been temporarily disabled by administrators."
        echo "         Check main_controller.txt for current status."
        return 1
    fi
    
    return 0
}

# Export function for use in other scripts
export -f check_component_enabled