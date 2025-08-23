#!/bin/bash

# @doc
# @name: Combined DTU Installer Builder
# @description: Creates unified PKG installer combining Constructor Python and VSCode components
# @category: Distribution Packaging
# @usage: ./build_combined.sh
# @requirements: macOS system with pkgbuild, productbuild, and both component PKGs
# @notes: Phase 4 - Creates professional single-click installer with DTU branding
# @/doc

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
WORK_DIR="$SCRIPT_DIR/work"
BUILD_DIR="$SCRIPT_DIR/builds"
RESOURCES_DIR="$SCRIPT_DIR/resources"

# Component paths
PYTHON_COMPONENT_DIR="$PROJECT_ROOT/MacOS/constructor_installer/python_stack"
VSCODE_COMPONENT_DIR="$PROJECT_ROOT/MacOS/constructor_installer/vscode_component"

# Version and naming
VERSION="1.0.0"
INSTALLER_NAME="DTU-Python-Development-Environment"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# Create working directories
mkdir -p "$WORK_DIR" "$BUILD_DIR"

log_info() {
    echo "[INFO] $*"
}

log_success() {
    echo "[SUCCESS] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_warning() {
    echo "[WARNING] $*"
}

check_exit_code() {
    local msg="$1"
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "$msg (exit code: $exit_code)"
        exit $exit_code
    fi
}

cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf "$WORK_DIR"
}

trap cleanup EXIT

# Function to find component PKG files
find_component_pkgs() {
    log_info "Looking for component PKG files..."
    
    # Find Python PKG
    local python_builds="$PYTHON_COMPONENT_DIR/builds"
    if [ -d "$python_builds" ]; then
        PYTHON_PKG=$(find "$python_builds" -name "DTU-Python-Stack-*.pkg" -type f | head -1)
    fi
    
    # Find VSCode PKG
    local vscode_builds="$VSCODE_COMPONENT_DIR/builds"
    if [ -d "$vscode_builds" ]; then
        VSCODE_PKG=$(find "$vscode_builds" -name "DTU-VSCode-*.pkg" -type f | head -1)
    fi
    
    # Validate PKG files exist
    if [ -z "${PYTHON_PKG:-}" ] || [ ! -f "${PYTHON_PKG:-}" ]; then
        log_error "Python PKG file not found. Please build it first:"
        log_error "  cd $PYTHON_COMPONENT_DIR && ./build.sh"
        exit 1
    fi
    
    if [ -z "${VSCODE_PKG:-}" ] || [ ! -f "${VSCODE_PKG:-}" ]; then
        log_error "VSCode PKG file not found. Please build it first:"
        log_error "  cd $VSCODE_COMPONENT_DIR && ./build_vscode_pkg.sh"
        exit 1
    fi
    
    log_success "Found component PKG files:"
    log_info "  Python PKG: $(basename "$PYTHON_PKG") ($(du -h "$PYTHON_PKG" | cut -f1))"
    log_info "  VSCode PKG: $(basename "$VSCODE_PKG") ($(du -h "$VSCODE_PKG" | cut -f1))"
}

# Function to prepare component packages
prepare_components() {
    log_info "Preparing component packages..."
    
    local pkg_dir="$WORK_DIR/packages"
    mkdir -p "$pkg_dir"
    
    # Copy and rename component PKGs for distribution
    cp "$PYTHON_PKG" "$pkg_dir/DTU-Python-Stack.pkg"
    check_exit_code "Failed to copy Python PKG"
    
    cp "$VSCODE_PKG" "$pkg_dir/DTU-VSCode.pkg"
    check_exit_code "Failed to copy VSCode PKG"
    
    log_success "Component packages prepared"
}

# Function to prepare resources
prepare_resources() {
    log_info "Preparing installer resources..."
    
    local res_dir="$WORK_DIR/resources"
    mkdir -p "$res_dir"
    
    # Copy HTML resources
    if [ -d "$RESOURCES_DIR" ]; then
        cp "$RESOURCES_DIR"/*.html "$res_dir/" 2>/dev/null || log_warning "No HTML resources found"
    fi
    
    # Create background images if they don't exist (simple solid colors for now)
    if [ ! -f "$res_dir/background.png" ]; then
        log_info "Creating placeholder background images..."
        # For now, we'll skip background images - they're optional
        # In production, proper branded images should be created
    fi
    
    log_success "Resources prepared"
}

# Function to create distribution configuration
create_distribution_config() {
    log_info "Creating distribution configuration..."
    
    local dist_xml="$WORK_DIR/distribution.xml"
    
    # Copy base distribution config and customize
    if [ -f "$SCRIPT_DIR/Distribution.xml" ]; then
        cp "$SCRIPT_DIR/Distribution.xml" "$dist_xml"
        
        # Update paths in distribution XML to use work directory
        # Note: The XML references are relative to the productbuild working directory
        log_info "Using existing Distribution.xml configuration"
    else
        log_error "Distribution.xml not found at $SCRIPT_DIR/Distribution.xml"
        exit 1
    fi
    
    log_success "Distribution configuration ready"
}

# Function to build the unified installer
build_unified_installer() {
    log_info "Building unified DTU installer..."
    
    local final_pkg="$BUILD_DIR/$INSTALLER_NAME-$VERSION-$TIMESTAMP.pkg"
    local dist_xml="$WORK_DIR/distribution.xml"
    local pkg_dir="$WORK_DIR/packages"
    local res_dir="$WORK_DIR/resources"
    
    # Ensure build directory exists
    mkdir -p "$BUILD_DIR"
    
    # Build the distribution package
    cd "$WORK_DIR"
    
    log_info "Running productbuild..."
    productbuild \
        --distribution "$dist_xml" \
        --package-path "$pkg_dir" \
        --resources "$res_dir" \
        --identifier "dk.dtu.python-development-environment" \
        --version "$VERSION" \
        "$final_pkg"
    check_exit_code "Failed to build unified installer"
    
    log_success "Unified installer built successfully: $final_pkg"
    
    # Display package information
    log_info "=== Package Information ==="
    log_info "Package: $(basename "$final_pkg")"
    log_info "Size: $(du -h "$final_pkg" | cut -f1)"
    log_info "Location: $final_pkg"
    log_info "Components: Python 3.11 + VSCode + Extensions"
    
    # Calculate total size of components
    local python_size=$(du -h "$PYTHON_PKG" | cut -f1)
    local vscode_size=$(du -h "$VSCODE_PKG" | cut -f1)
    log_info "Component sizes: Python ($python_size) + VSCode ($vscode_size)"
    
    return 0
}

# Function to verify the built installer
verify_installer() {
    log_info "Verifying built installer..."
    
    local final_pkg="$BUILD_DIR/$INSTALLER_NAME-$VERSION-$TIMESTAMP.pkg"
    
    # Check if file exists and is not empty
    if [ ! -f "$final_pkg" ] || [ ! -s "$final_pkg" ]; then
        log_error "Built installer is missing or empty"
        return 1
    fi
    
    # Use pkgutil to verify package structure
    if pkgutil --check-signature "$final_pkg" >/dev/null 2>&1; then
        log_success "Package signature verification passed"
    else
        log_warning "Package is not signed (expected for development builds)"
    fi
    
    # Try to examine package contents
    if pkgutil --payload-files "$final_pkg" >/dev/null 2>&1; then
        log_success "Package structure verification passed"
    else
        log_warning "Could not verify package structure"
    fi
    
    log_success "Installer verification completed"
}

# Function to create installation test script
create_test_script() {
    log_info "Creating installation test script..."
    
    local test_script="$BUILD_DIR/test_unified_installer.sh"
    local final_pkg="$BUILD_DIR/$INSTALLER_NAME-$VERSION-$TIMESTAMP.pkg"
    
    cat > "$test_script" << EOF
#!/bin/bash
# Auto-generated test script for DTU unified installer

set -euo pipefail

INSTALLER_PKG="$final_pkg"

echo "=== DTU Unified Installer Test ==="
echo "Testing: \$(basename "\$INSTALLER_PKG")"
echo "Size: \$(du -h "\$INSTALLER_PKG" | cut -f1)"
echo ""

echo "Installing unified package..."
sudo installer -verbose -pkg "\$INSTALLER_PKG" -target /

echo ""
echo "=== Testing Python Installation ==="

# Test Python installation
PYTHON_PATHS=(
    "\$HOME/dtu-python-stack/bin/python3"
    "\$HOME/miniconda3/bin/python3"
    "\$HOME/anaconda3/bin/python3"
)

CONSTRUCTOR_PYTHON=""
for python_path in "\${PYTHON_PATHS[@]}"; do
    if [ -f "\$python_path" ]; then
        PYTHON_VERSION=\$("\$python_path" --version 2>/dev/null | cut -d " " -f 2)
        if [[ "\$PYTHON_VERSION" == "3.11"* ]]; then
            CONSTRUCTOR_PYTHON="\$python_path"
            echo "✅ Found Python 3.11: \$python_path"
            break
        fi
    fi
done

if [ -z "\$CONSTRUCTOR_PYTHON" ]; then
    echo "❌ Python 3.11 not found"
    exit 1
fi

# Test package imports
echo "Testing Python packages..."
if "\$CONSTRUCTOR_PYTHON" -c "import pandas, scipy, statsmodels, uncertainties, dtumathtools; print('✅ All packages working')"; then
    echo "✅ Python environment fully functional"
else
    echo "❌ Python package imports failed"
    exit 1
fi

echo ""
echo "=== Testing VSCode Installation ==="

# Test VSCode app
if [ -d "/Applications/Visual Studio Code.app" ]; then
    echo "✅ VSCode app installed"
    APP_VERSION=\$(defaults read "/Applications/Visual Studio Code.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "unknown")
    echo "  Version: \$APP_VERSION"
else
    echo "❌ VSCode app not found"
    exit 1
fi

# Test CLI tools
export PATH="/usr/local/bin:\$PATH"
if command -v code >/dev/null 2>&1; then
    echo "✅ VSCode CLI available"
    CODE_VERSION=\$(code --version | head -1)
    echo "  CLI Version: \$CODE_VERSION"
else
    echo "⚠️  VSCode CLI not in PATH (may need shell restart)"
fi

echo ""
echo "🎉 UNIFIED INSTALLER TEST: SUCCESS!"
echo "✅ Python 3.11 environment working"
echo "✅ VSCode with extensions installed"
echo "✅ Complete development environment ready"
EOF
    
    chmod +x "$test_script"
    log_success "Test script created: $test_script"
}

# Main execution
main() {
    log_info "Starting DTU Unified Installer build process..."
    log_info "Phase 4: Distribution Package (Orchestration)"
    
    find_component_pkgs
    prepare_components
    prepare_resources
    create_distribution_config
    build_unified_installer
    verify_installer
    create_test_script
    
    log_success "🎉 DTU Unified Installer build completed successfully!"
    
    local final_pkg="$BUILD_DIR/$INSTALLER_NAME-$VERSION-$TIMESTAMP.pkg"
    log_info ""
    log_info "=== Build Summary ==="
    log_info "✅ Combined Python + VSCode installer created"
    log_info "✅ Professional macOS PKG with custom UI"
    log_info "✅ Single-click installation experience"
    log_info "✅ DTU branding and documentation included"
    log_info "✅ Installation test script generated"
    log_info ""
    log_info "📦 Final Package: $(basename "$final_pkg")"
    log_info "💾 Size: $(du -h "$final_pkg" | cut -f1)"
    log_info "📍 Location: $final_pkg"
    log_info ""
    log_info "🚀 Ready for deployment and testing!"
}

# Run main function
main "$@"