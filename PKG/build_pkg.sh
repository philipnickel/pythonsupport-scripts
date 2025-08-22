#!/bin/bash
# Build DTU Python Environment PKG locally
# Usage: ./build_pkg.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
PKG_NAME="DTU_Python_Environment"
VERSION="1.0.0"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Building DTU Python Environment PKG..."
echo "Version: $VERSION"
echo ""

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Create payload directory with bundled components
echo "Creating payload with bundled components..."
PAYLOAD_DIR="$BUILD_DIR/payload"

# Create the installation directory structure
mkdir -p "$PAYLOAD_DIR/usr/local/bin"
mkdir -p "$PAYLOAD_DIR/usr/local/share/dtu-python-env/Components"

# Copy the orchestrator script
echo "Copying orchestrator..."
cp "$SCRIPT_DIR/pkg_orchestrator.sh" "$PAYLOAD_DIR/usr/local/bin/dtu_orchestrator.sh"
chmod +x "$PAYLOAD_DIR/usr/local/bin/dtu_orchestrator.sh"

# Copy all components
echo "Copying components..."
cp -r "$REPO_ROOT/MacOS/Components/"* "$PAYLOAD_DIR/usr/local/share/dtu-python-env/Components/"

# Make all shell scripts executable
find "$PAYLOAD_DIR" -name "*.sh" -exec chmod +x {} \;

echo "Payload created with components:"
find "$PAYLOAD_DIR" -type f | head -10

# Create component package with payload
echo "Creating component package..."
pkgbuild \
    --root "$PAYLOAD_DIR" \
    --scripts "$SCRIPT_DIR/Scripts" \
    --identifier "dk.dtu.python-environment" \
    --version "$VERSION" \
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