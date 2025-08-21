#!/bin/bash
# DTU Python Installer PKG Build Script
# Copies components from single source of truth and localizes URLs

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/metadata/config.sh"

echo "=== DTU Python Installer PKG Build ==="
echo "Build root: $BUILD_ROOT"
echo "Components source: $COMPONENTS_SOURCE"
echo "Package version: $PKG_VERSION"
echo ""

# Clean and create build directories
echo "Setting up build directories..."
rm -rf "$TEMP_BUILD_DIR"
mkdir -p "$TEMP_BUILD_DIR"
mkdir -p "$BUILDS_DIR"
mkdir -p "$PKG_ROOT$LOCAL_INSTALL_PATH"
mkdir -p "$PKG_ROOT$LOCAL_INSTALL_PATH/Components"
mkdir -p "$PKG_ROOT$LOCAL_INSTALL_PATH/Components/Diagnostics"

# Function to localize script URLs to use local files
localize_script() {
    local input_file="$1"
    local output_file="$2"
    
    echo "  Localizing: $(basename "$input_file")"
    
    # Create output directory if needed
    mkdir -p "$(dirname "$output_file")"
    
    # Copy and modify the script to use local paths
    # Handle various URL patterns used in the scripts
    sed \
        -e "s|https://raw\.githubusercontent\.com/\${REMOTE_PS:-dtudk/pythonsupport-scripts}/\${BRANCH_PS:-main}/MacOS/Components/|$LOCAL_INSTALL_PATH/Components/|g" \
        -e "s|https://raw\.githubusercontent\.com/\${DIAG_REMOTE_PS:-philipnickel/pythonsupport-scripts}/\${DIAG_BRANCH_PS:-main}/MacOS/Components/Diagnostics/|$LOCAL_INSTALL_PATH/Components/Diagnostics/|g" \
        -e "s|https://raw\.githubusercontent\.com/dtudk/pythonsupport-scripts/main/MacOS/Components/|$LOCAL_INSTALL_PATH/Components/|g" \
        -e "s|https://raw\.githubusercontent\.com/philipnickel/pythonsupport-scripts/main/MacOS/Components/Diagnostics/|$LOCAL_INSTALL_PATH/Components/Diagnostics/|g" \
        -e "s|\$(curl -fsSL \"https://raw\.githubusercontent\.com/\${REMOTE_PS:-dtudk/pythonsupport-scripts}/\${BRANCH_PS:-main}/MacOS/Components/|\"$LOCAL_INSTALL_PATH/Components/|g" \
        -e "s|\$(curl -fsSL https://raw\.githubusercontent\.com/\${REMOTE_PS:-dtudk/pythonsupport-scripts}/\${BRANCH_PS:-main}/MacOS/Components/|$LOCAL_INSTALL_PATH/Components/|g" \
        -e "s|\$(curl -fsSL https://raw\.githubusercontent\.com/\${DIAG_REMOTE_PS:-philipnickel/pythonsupport-scripts}/\${DIAG_BRANCH_PS:-main}/MacOS/Components/Diagnostics/|$LOCAL_INSTALL_PATH/Components/Diagnostics/|g" \
        -e "s|/bin/bash -c \"\$(curl -fsSL https://raw\.githubusercontent\.com/\${REMOTE_PS:-dtudk/pythonsupport-scripts}/\${BRANCH_PS:-main}/MacOS/Components/|/bin/bash $LOCAL_INSTALL_PATH/Components/|g" \
        -e "s|/bin/bash -c \"\$(curl -fsSL https://raw\.githubusercontent\.com/\${DIAG_REMOTE_PS:-philipnickel/pythonsupport-scripts}/\${DIAG_BRANCH_PS:-main}/MacOS/Components/Diagnostics/|/bin/bash $LOCAL_INSTALL_PATH/Components/Diagnostics/|g" \
        -e 's|")"|"|g' \
        "$input_file" > "$output_file"
    
    # Make executable
    chmod +x "$output_file"
}

# Copy and localize main components
echo "Copying and localizing main components..."
for component in "${COMPONENTS[@]}"; do
    source_file="$COMPONENTS_SOURCE/$component"
    dest_file="$PKG_ROOT$LOCAL_INSTALL_PATH/Components/$component"
    
    if [[ -f "$source_file" ]]; then
        localize_script "$source_file" "$dest_file"
    else
        echo "  WARNING: Component not found: $source_file"
    fi
done

# Copy and localize diagnostics components
echo "Copying and localizing diagnostics components..."
for diag_component in "${DIAGNOSTICS_COMPONENTS[@]}"; do
    source_file="$COMPONENTS_SOURCE/Diagnostics/$diag_component"
    dest_file="$PKG_ROOT$LOCAL_INSTALL_PATH/Components/Diagnostics/$diag_component"
    
    if [[ -f "$source_file" ]]; then
        localize_script "$source_file" "$dest_file"
    else
        echo "  WARNING: Diagnostics component not found: $source_file"
    fi
done

# Create the main installer script for dummy PKG
echo "Creating dummy installer script..."
cat > "$PKG_ROOT$LOCAL_INSTALL_PATH/install.sh" << 'EOF'
#!/bin/bash
# DTU Python Support - Minimal Dummy PKG
# Phase 1: Basic PKG installation test

echo "🎉 DTU Python Support PKG installed successfully!"
echo "📋 Installation details:"
echo "  • Installation path: /usr/local/share/dtu-pythonsupport/"
echo "  • Version: v1.0.0 (minimal dummy)"
echo "  • Phase: 1 - Basic PKG functionality test"
echo ""
echo "✅ PKG installation verification complete."

# Create a simple status file to verify installation
echo "DTU_PYTHON_SUPPORT_PKG_INSTALLED=true" > "/usr/local/share/dtu-pythonsupport/.pkg_status"
echo "PKG_VERSION=1.0.0-dummy" >> "/usr/local/share/dtu-pythonsupport/.pkg_status"
echo "INSTALL_DATE=\$(date)" >> "/usr/local/share/dtu-pythonsupport/.pkg_status"
EOF

chmod +x "$PKG_ROOT$LOCAL_INSTALL_PATH/install.sh"

# Create postinstall script for minimal PKG
echo "Creating minimal PKG postinstall script..."
mkdir -p "$TEMP_BUILD_DIR/Scripts"
cat > "$TEMP_BUILD_DIR/Scripts/postinstall" << 'EOF'
#!/bin/bash
# Minimal PKG postinstall script - Phase 1

echo "=== DTU Python Support PKG - Phase 1 Installation ==="
echo "Files installed to: /usr/local/share/dtu-pythonsupport/"
echo ""

# Run the dummy installer script
/usr/local/share/dtu-pythonsupport/install.sh

echo ""
echo "=== Phase 1 PKG Installation Complete ==="
exit 0
EOF

chmod +x "$TEMP_BUILD_DIR/Scripts/postinstall"

# Build the PKG
echo "Building PKG..."
PKG_FILE="$BUILDS_DIR/DTU-Python-FirstYear-v${PKG_VERSION}.pkg"

# Create component package
pkgbuild --root "$PKG_ROOT" \
         --identifier "$PKG_IDENTIFIER" \
         --version "$PKG_VERSION" \
         --scripts "$TEMP_BUILD_DIR/Scripts" \
         "$PKG_FILE"

if [[ $? -eq 0 ]]; then
    echo ""
    echo "=== BUILD SUCCESSFUL ==="
    echo "PKG file: $PKG_FILE"
    echo "Size: $(du -h "$PKG_FILE" | cut -f1)"
    echo ""
    echo "To install: sudo installer -pkg \"$PKG_FILE\" -target /"
    echo "To test: make install"
else
    echo ""
    echo "=== BUILD FAILED ==="
    exit 1
fi