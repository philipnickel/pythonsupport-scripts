#!/bin/bash
# PKG Self-Contained Orchestrator
# Uses bundled scripts instead of downloading from GitHub

set -euo pipefail

# Configuration for self-contained PKG
readonly ORCHESTRATOR_NAME="DTU First Year Setup"
readonly BUNDLE_DIR="/usr/local/share/dtu-python-env/Components"

# Set install method for analytics
export PIS_INSTALL_METHOD="${PIS_INSTALL_METHOD:-PKG}"
export PYTHON_VERSION_PS="${PYTHON_VERSION_PS:-3.11}"

# Load bundled utilities
if [[ -f "$BUNDLE_DIR/Shared/minimal_utils.sh" ]]; then
    source "$BUNDLE_DIR/Shared/minimal_utils.sh"
else
    # Fallback minimal functions if utils not available
    echo_success() { echo "✅ $1"; }
    echo_error() { echo "❌ $1"; }
    echo_info() { echo "ℹ️  $1"; }
fi

# Component installation function
install_component() {
    local component_name="$1"
    local component_script="$2"
    
    echo_info "Installing $component_name..."
    
    if [[ -f "$component_script" ]]; then
        if /bin/bash "$component_script"; then
            echo_success "$component_name installed successfully"
            return 0
        else
            echo_error "$component_name installation failed"
            return 1
        fi
    else
        echo_error "Component script not found: $component_script"
        return 1
    fi
}

echo "=== $ORCHESTRATOR_NAME ==="
echo "Installing development environment using bundled components..."
echo "Bundle directory: $BUNDLE_DIR"
echo ""

# Debug information
echo "DEBUG: Current user: $(id)"
echo "DEBUG: Current directory: $(pwd)"
echo "DEBUG: Environment variables:"
env | grep -E "(PIS_|PYTHON_)" || echo "No PIS_/PYTHON_ variables found"

# Check if bundle directory exists
echo "DEBUG: Checking bundle directory..."
ls -la /usr/local/share/ || echo "ERROR: /usr/local/share not found"
ls -la "$BUNDLE_DIR" || echo "ERROR: Bundle directory not accessible"

if [[ ! -d "$BUNDLE_DIR" ]]; then
    echo_error "Bundle directory not found: $BUNDLE_DIR"
    echo "This PKG may be corrupted or incomplete."
    exit 1
fi

# List available components
echo "DEBUG: Available components:"
find "$BUNDLE_DIR" -name "*.sh" | head -10

# Install components using bundled scripts
success_count=0
total_components=0

# Python/Miniconda
echo "----------------------------------------"
((total_components++))
if install_component "Python/Miniconda" "$BUNDLE_DIR/Python/install.sh"; then
    ((success_count++))
fi

# Python Environment Setup
echo "----------------------------------------"
((total_components++))
if install_component "Python Environment" "$BUNDLE_DIR/Python/first_year_setup.sh"; then
    ((success_count++))
fi

# VS Code
echo "----------------------------------------"
((total_components++))
if install_component "VS Code" "$BUNDLE_DIR/VSC/install.sh"; then
    ((success_count++))
fi

echo "----------------------------------------"
echo "=== Installation Summary ==="
echo "Successfully installed: $success_count/$total_components components"

if [[ $success_count -eq $total_components ]]; then
    echo_success "All components installed successfully!"
    echo ""
    echo "Your DTU Python development environment is ready!"
    echo ""
    echo "Next steps:"
    echo "1. Open a new terminal window"
    echo "2. Run: conda --version"
    echo "3. Run: python --version"
    echo "4. Run: code --version"
    exit 0
else
    echo_error "Some components failed to install"
    echo "Please check the error messages above"
    exit 1
fi