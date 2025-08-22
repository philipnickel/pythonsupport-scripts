#!/bin/bash
# Build DTU Python Environment PKG locally
# Usage: ./build_pkg.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
PKG_NAME="DTU_Python_Environment"
VERSION="1.0.0"

echo "Building DTU Python Environment PKG..."
echo "Version: $VERSION"
echo ""

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Create empty payload directory (scripts-only PKG)
mkdir -p "$BUILD_DIR/payload"
touch "$BUILD_DIR/payload/.keep"

# Create component package
echo "Creating component package..."
pkgbuild \
    --root "$BUILD_DIR/payload" \
    --scripts "$SCRIPT_DIR/Scripts" \
    --identifier "dk.dtu.python-environment" \
    --version "$VERSION" \
    --install-location "/" \
    "$BUILD_DIR/${PKG_NAME}-component.pkg"

# Create distribution XML
cat > "$BUILD_DIR/distribution.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>DTU Python Environment</title>
    <welcome file="welcome.txt"/>
    <background file="background.png" mime-type="image/png" alignment="left" scaling="proportional"/>
    <options customize="never" require-scripts="true" hostArchitectures="arm64,x86_64"/>
    
    <pkg-ref id="dk.dtu.python-environment"/>
    
    <choices-outline>
        <line choice="default">
            <line choice="dk.dtu.python-environment"/>
        </line>
    </choices-outline>
    
    <choice id="default"/>
    <choice id="dk.dtu.python-environment" visible="false">
        <pkg-ref id="dk.dtu.python-environment"/>
    </choice>
    
    <pkg-ref id="dk.dtu.python-environment" version="$VERSION" onConclusion="none">${PKG_NAME}-component.pkg</pkg-ref>
</installer-gui-script>
EOF

# Copy resources
cp "$SCRIPT_DIR/Resources/welcome.txt" "$BUILD_DIR/"

# Create a simple background if it doesn't exist
if [[ ! -f "$SCRIPT_DIR/Resources/background.png" ]]; then
    echo "Creating default background..."
    # Create a simple 1x1 transparent PNG as placeholder
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAGA4849kwAAAABJRU5ErkJggg==" | base64 -d > "$BUILD_DIR/background.png"
else
    cp "$SCRIPT_DIR/Resources/background.png" "$BUILD_DIR/"
fi

# Build the final distribution package
echo "Building distribution package..."
productbuild \
    --distribution "$BUILD_DIR/distribution.xml" \
    --resources "$BUILD_DIR" \
    --package-path "$BUILD_DIR" \
    "$SCRIPT_DIR/${PKG_NAME}.pkg"

# Clean up build directory
rm -rf "$BUILD_DIR"

echo ""
echo "✅ PKG built successfully: $SCRIPT_DIR/${PKG_NAME}.pkg"
echo ""
echo "To test locally:"
echo "  sudo installer -pkg '$SCRIPT_DIR/${PKG_NAME}.pkg' -target /"
echo ""
echo "To upload to GitHub:"
echo "  gh release upload <tag> '$SCRIPT_DIR/${PKG_NAME}.pkg'"