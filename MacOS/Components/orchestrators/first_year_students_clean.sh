#!/bin/bash
# First Year Students Orchestrator - Clean Implementation
# Complete installation orchestrator for DTU first year students
# Usage: /bin/bash -c "$(curl -fsSL .../first_year_students_clean.sh)"

set -euo pipefail

# Load minimal utilities
REMOTE_PS="${REMOTE_PS:-dtudk/pythonsupport-scripts}"  
BRANCH_PS="${BRANCH_PS:-main}"
BASE_URL="https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared"

eval "$(curl -fsSL "$BASE_URL/minimal_utils.sh")"

# Configuration
readonly ORCHESTRATOR_NAME="DTU First Year Setup"
readonly COMPONENTS=(
    "Python/Miniconda:${BASE_URL}/../Python/install_clean.sh"
    "Python Environment:${BASE_URL}/../Python/first_year_setup_clean.sh" 
    "VS Code:${BASE_URL}/../VSC/install_clean.sh"
)

# Track orchestrator start
if declare -f piwik_log >/dev/null 2>&1; then
    # Convert to lowercase (compatible with older bash)
    method_lower=$(echo "$INSTALL_METHOD" | tr '[:upper:]' '[:lower:]')
    piwik_log "orchestrator_${method_lower}_start"
fi

echo "=== $ORCHESTRATOR_NAME ==="
echo "Installing development environment..."
echo

install_component() {
    local component_name="$1"
    local component_url="$2"
    
    echo "Processing $component_name..."
    
    # Run component and capture exit code
    local output
    local exit_code
    
    if output=$(/bin/bash -c "$(curl -fsSL "$component_url")" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    # Display output with proper indentation
    echo "$output" | sed 's/^/  /'
    
    # Handle exit codes
    case $exit_code in
        0)
            echo "  → Installation completed"
            return 0
            ;;
        10) 
            echo "  → Already installed, skipped"
            return 0  # Don't fail orchestrator for "already installed"
            ;;
        *)
            echo "  → Installation failed (exit code: $exit_code)"
            return 1
            ;;
    esac
}

install_all_components() {
    local failed_components=()
    local total_components=${#COMPONENTS[@]}
    local current=0
    
    for component_spec in "${COMPONENTS[@]}"; do
        ((current++))
        
        IFS=':' read -r component_name component_url <<< "$component_spec"
        
        echo "[$current/$total_components] $component_name"
        
        if install_component "$component_name" "$component_url"; then
            echo "✓ $component_name ready"
        else
            echo "✗ $component_name failed"
            failed_components+=("$component_name")
        fi
        
        echo
    done
    
    # Summary
    echo "=== Installation Summary ==="
    if [[ ${#failed_components[@]} -eq 0 ]]; then
        echo "✓ All components installed successfully!"
        echo "Your development environment is ready."
        
        # Track success
        if declare -f piwik_log >/dev/null 2>&1; then
            method_lower=$(echo "$INSTALL_METHOD" | tr '[:upper:]' '[:lower:]')
            piwik_log "orchestrator_${method_lower}_success"
        fi
        
        return 0
    else
        echo "✗ Some components failed to install:"
        for component in "${failed_components[@]}"; do
            echo "  - $component" 
        done
        echo
        echo "Please check the error messages above and try again."
        
        # Track failure
        if declare -f piwik_log >/dev/null 2>&1; then
            method_lower=$(echo "$INSTALL_METHOD" | tr '[:upper:]' '[:lower:]')
            piwik_log "orchestrator_${method_lower}_partial_failure"
        fi
        
        return 1
    fi
}

# Main execution
main() {
    install_all_components
}

if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    main
fi