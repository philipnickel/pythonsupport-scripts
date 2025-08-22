#!/bin/bash
# Main Controller Check Utility
# Verifies if component is enabled via main_controller.yml
# Usage: check_component_enabled "component_name" || exit 1

check_component_enabled() {
    local component_name="$1"
    local platform="${2:-macOS}"
    local controller_url="https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/main_controller.yml"
    
    # Fetch main controller with fallback
    local controller_content
    if ! controller_content=$(curl -fsSL "$controller_url" 2>/dev/null); then
        # If controller fetch fails, allow execution (fail-open for reliability)
        echo "WARNING: Could not fetch controller configuration, proceeding anyway"
        return 0
    fi
    
    # Parse YAML to check if component is enabled
    local platform_lower=$(echo "$platform" | tr '[:upper:]' '[:lower:]')
    local component_status
    
    # Look for the component under the platform section
    component_status=$(echo "$controller_content" | awk "
        /^${platform_lower}:/ { in_platform=1; next }
        in_platform && /^[[:space:]]*${component_name}:[[:space:]]*/ { 
            gsub(/^[[:space:]]*${component_name}:[[:space:]]*/, \"\")
            gsub(/#.*/, \"\")
            gsub(/[[:space:]]*$/, \"\")
            print \$0
            exit
        }
        /^[a-zA-Z]/ && in_platform { in_platform=0 }
    ")
    
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