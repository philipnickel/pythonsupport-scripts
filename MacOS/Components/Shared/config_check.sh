#!/bin/bash
# Main Controller Check Utility
# Verifies if component is enabled via main_controller.txt
# Usage: check_component_enabled "component_name" || exit 1

check_component_enabled() {
    local component_name="$1"
    local controller_url="https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/main_controller.txt"
    
    echo "DEBUG: Checking component: $component_name"
    echo "DEBUG: Controller URL: $controller_url"
    
    # Fetch main controller with fallback
    local controller_content
    if ! controller_content=$(curl -fsSL "$controller_url" 2>/dev/null); then
        echo "DEBUG: Failed to fetch controller, allowing execution"
        return 0
    fi
    
    echo "DEBUG: Controller content:"
    echo "$controller_content"
    
    # Simple grep for component=disabled
    if echo "$controller_content" | grep -q "^${component_name}=disabled"; then
        echo "WARNING: $component_name installation is currently disabled"
        echo "         This component has been temporarily disabled by administrators."
        echo "         Check main_controller.txt for current status."
        return 1
    fi
    
    echo "DEBUG: Component $component_name is enabled"
    return 0
}

# Export function for use in other scripts
export -f check_component_enabled