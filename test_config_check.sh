#!/bin/bash
# Main Controller Check Utility
# Verifies if component is enabled via main_controller.yml
# Usage: check_component_enabled "component_name" || exit 1

check_component_enabled() {
    local component_name="$1"
    local platform="${2:-macOS}"  # Default to macOS
    local controller_url="test_controller.yml"
    
    # Fetch main controller with fallback
    local controller_content
    if ! controller_content=$(curl -fsSL "$controller_url" 2>/dev/null); then
        # If controller fetch fails, allow execution (fail-open for reliability)
        return 0
    fi
    
    # Check maintenance mode first
    if echo "$controller_content" | grep -q "maintenance_mode: enabled"; then
        echo "WARNING: System is currently under maintenance"
        local maintenance_msg=$(echo "$controller_content" | grep "maintenance_message:" | sed 's/.*maintenance_message: *["\x27]*\([^"\x27]*\)["\x27]*.*/\1/')
        if [[ -n "$maintenance_msg" ]]; then
            echo "         Message: $maintenance_msg"
        fi
        echo "         Please check the repository for updates and try again later."
        return 1
    fi
    
    # Parse YAML to check if component is enabled
    local platform_lower=$(echo "$platform" | tr '[:upper:]' '[:lower:]')
    local component_status
    
    case "$component_name" in
        "orchestrator"|"legacy"|"pkg"|"msi")
            component_status=$(echo "$controller_content" | grep -A 10 "^$platform_lower:" | grep "  $component_name:" | awk '{print $2}')
            ;;
        *)
            # Unknown component, allow by default
            return 0
            ;;
    esac
    
    # Check if component is disabled
    if [[ "$component_status" == "disabled" ]]; then
        echo "WARNING: $component_name installation is currently disabled"
        echo "         This component has been temporarily disabled by administrators."
        echo "         Check main_controller.yml for current status."
        return 1
    fi
    
    return 0
}

# Export function for use in other scripts
export -f check_component_enabled