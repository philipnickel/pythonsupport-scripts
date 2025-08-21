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
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$BUILDS_DIR"
mkdir -p "$SCRIPTS_DIR"
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
    
    # Copy and modify the script to use local file paths instead of curl
    # We need to replace eval "$(curl ...)" with source "/local/path"
    sed \
        -e 's|eval "\$(curl -fsSL "https://raw\.githubusercontent\.com/\${REMOTE_PS:-dtudk/pythonsupport-scripts}/\${BRANCH_PS:-main}/MacOS/Components/Shared/master_utils\.sh")"|\. "/usr/local/share/dtu-pythonsupport/Components/Shared/master_utils.sh"|g' \
        -e 's|eval "\$(curl -fsSL "https://raw\.githubusercontent\.com/\${DIAG_REMOTE_PS:-philipnickel/pythonsupport-scripts}/\${DIAG_BRANCH_PS:-main}/MacOS/Components/Diagnostics/\([^"]*\)\.sh")"|\. "/usr/local/share/dtu-pythonsupport/Components/Diagnostics/\1.sh"|g' \
        -e 's|/bin/bash -c "\$(curl -fsSL https://raw\.githubusercontent\.com/\${REMOTE_PS:-dtudk/pythonsupport-scripts}/\${BRANCH_PS:-main}/MacOS/Components/\([^"]*\)\.sh)"|/bin/bash "/usr/local/share/dtu-pythonsupport/Components/\1.sh"|g' \
        -e 's|/bin/bash -c "\$(curl -fsSL https://raw\.githubusercontent\.com/\${DIAG_REMOTE_PS:-philipnickel/pythonsupport-scripts}/\${DIAG_BRANCH_PS:-main}/MacOS/Components/Diagnostics/\([^"]*\)\.sh)"|/bin/bash "/usr/local/share/dtu-pythonsupport/Components/Diagnostics/\1.sh"|g' \
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

# Create the main installer script for Homebrew PKG
echo "Creating Homebrew installer script..."
cat > "$PKG_ROOT$LOCAL_INSTALL_PATH/install.sh" << 'EOF'
#!/bin/bash
# DTU Python Support - Phase 2: Homebrew Component
# This script installs Homebrew using local components

echo "=== DTU Python Support PKG - Phase 2 Installation ==="
echo "📦 Installing Homebrew component..."
echo "Installation path: /usr/local/share/dtu-pythonsupport/"
echo ""

# Set environment to use local scripts
export REMOTE_PS="local-pkg"
export BRANCH_PS="local-pkg"

# Run Homebrew installation using local component
echo "🍺 Installing Homebrew..."
/bin/bash "/usr/local/share/dtu-pythonsupport/Components/Homebrew/install.sh"
HOMEBREW_EXIT_CODE=$?

if [ $HOMEBREW_EXIT_CODE -eq 0 ]; then
    echo "✅ Homebrew installation completed successfully!"
else
    echo "❌ Homebrew installation failed with exit code: $HOMEBREW_EXIT_CODE"
fi

# Create status file to track installation
echo "DTU_PYTHON_SUPPORT_PKG_INSTALLED=true" > "/usr/local/share/dtu-pythonsupport/.pkg_status"
echo "PKG_VERSION=1.0.0-homebrew" >> "/usr/local/share/dtu-pythonsupport/.pkg_status"
echo "INSTALL_DATE=\$(date)" >> "/usr/local/share/dtu-pythonsupport/.pkg_status"
echo "HOMEBREW_COMPONENT=installed" >> "/usr/local/share/dtu-pythonsupport/.pkg_status"
echo "HOMEBREW_EXIT_CODE=$HOMEBREW_EXIT_CODE" >> "/usr/local/share/dtu-pythonsupport/.pkg_status"

echo ""
echo "=== Phase 2 PKG Installation Complete ==="
echo "Components installed: Homebrew"
echo "Exit code: $HOMEBREW_EXIT_CODE"

exit $HOMEBREW_EXIT_CODE
EOF

chmod +x "$PKG_ROOT$LOCAL_INSTALL_PATH/install.sh"

# Create postinstall script for Homebrew PKG
echo "Creating Homebrew PKG postinstall script..."
cat > "$SCRIPTS_DIR/postinstall" << 'EOF'
#!/bin/bash
# Homebrew PKG postinstall script - Phase 2

echo "=== DTU Python Support PKG - Phase 2 Installation ==="
echo "Files installed to: /usr/local/share/dtu-pythonsupport/"
echo "Components: Homebrew + dependencies"
echo ""

# Run the Homebrew installer script
/usr/local/share/dtu-pythonsupport/install.sh
INSTALL_EXIT_CODE=$?

echo ""
echo "=== Phase 2 PKG Installation Complete ==="
echo "Homebrew component installation exit code: $INSTALL_EXIT_CODE"

exit $INSTALL_EXIT_CODE
EOF

chmod +x "$SCRIPTS_DIR/postinstall"

# Build the PKG using productbuild
echo "Building PKG with productbuild..."
PKG_FILE="$BUILDS_DIR/DTU-Python-FirstYear-v${PKG_VERSION}.pkg"
COMPONENT_PKG="$BUILD_DIR/component.pkg"

# First create component package
echo "Creating component package..."
pkgbuild --root "$PKG_ROOT" \
         --identifier "$PKG_IDENTIFIER.component" \
         --version "$PKG_VERSION" \
         --scripts "$SCRIPTS_DIR" \
         "$COMPONENT_PKG"

if [[ $? -ne 0 ]]; then
    echo "❌ Component package creation failed"
    exit 1
fi

# Create Distribution.xml
echo "Creating Distribution.xml..."
cat > "$BUILD_DIR/Distribution.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <title>$PKG_NAME</title>
    <organization>dk.dtu.pythonsupport</organization>
    <domains enable_localSystem="true"/>
    <options customize="never" require-scripts="true" rootVolumeOnly="true" />
    
    <welcome file="welcome.rtf" />
    <license file="license.rtf" />
    <readme file="readme.rtf" />
    <conclusion file="conclusion.rtf" />
    
    <pkg-ref id="$PKG_IDENTIFIER.component"/>
    <choices-outline>
        <line choice="default">
            <line choice="$PKG_IDENTIFIER.component"/>
        </line>
    </choices-outline>
    
    <choice id="default"/>
    <choice id="$PKG_IDENTIFIER.component" visible="false">
        <pkg-ref id="$PKG_IDENTIFIER.component"/>
    </choice>
    
    <pkg-ref id="$PKG_IDENTIFIER.component" version="$PKG_VERSION" onConclusion="none">component.pkg</pkg-ref>
</installer-gui-script>
EOF

# Build final PKG with productbuild using permanent resources
echo "Building distribution package..."
productbuild --distribution "$BUILD_DIR/Distribution.xml" \
             --package-path "$BUILD_DIR" \
             --resources "$RESOURCES_DIR" \
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