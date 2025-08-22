#!/bin/bash
# Legacy compatibility wrapper for MacOS installation
# Uses clean component architecture with graceful error handling

set -euo pipefail

# Configuration
REMOTE_PS="${REMOTE_PS:-dtudk/pythonsupport-scripts}"
BRANCH_PS="${BRANCH_PS:-main}"
export REMOTE_PS BRANCH_PS

readonly BASE_URL="https://raw.githubusercontent.com/$REMOTE_PS/$BRANCH_PS/MacOS/Components"

echo "DTU Python Installation - Legacy Mode"
echo "Using components from: $BASE_URL"
echo

install_component_legacy() {
    local component_name="$1"
    local component_url="$2"
    
    echo "Installing $component_name..."
    
    local exit_code
    if /bin/bash -c "$(curl -fsSL "$component_url")"; then
        exit_code=$?
    else
        exit_code=$?
    fi
    
    # Handle exit codes (0=success, 10=already installed, 1=failure)
    case $exit_code in
        0|10)
            echo "✓ $component_name ready"
            return 0
            ;;
        *)
            echo "✗ $component_name failed"
            return $exit_code
            ;;
    esac
}

main() {
    local failed=0
    
    # Install Python environment
    if ! install_component_legacy "Python Environment" "$BASE_URL/Python/first_year_setup.sh"; then
        failed=1
    fi
    
    echo
    
    # Install VS Code
    if ! install_component_legacy "VS Code" "$BASE_URL/VSC/install.sh"; then
        failed=1
    fi
    
    echo
    
    # Final result
    if [[ $failed -eq 0 ]]; then
        echo "✓ Installation completed successfully!"
        echo "Your development environment is ready."
    else
        echo "✗ Some components failed to install."
        echo "Please check the error messages above."
        exit 1
    fi
    
    echo
    echo "Script finished. You may now close the terminal."
}

main