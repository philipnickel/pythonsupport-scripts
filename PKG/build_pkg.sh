#!/bin/bash
# DTU Python Environment PKG Build Script
# Creates a self-contained PKG with bundled components and RTF files

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
    --install-location "/" \
    "$BUILD_DIR/${PKG_NAME}-component.pkg"

# Create distribution package with RTF files
echo "Creating distribution package with RTF files..."
productbuild \
    --distribution "$SCRIPT_DIR/distribution.xml" \
    --resources "$SCRIPT_DIR/Resources" \
    --package-path "$BUILD_DIR" \
    "$SCRIPT_DIR/${PKG_NAME}.pkg"

echo ""
echo "✅ PKG built successfully: $SCRIPT_DIR/${PKG_NAME}.pkg"
echo ""
echo "To test locally:"
echo "  sudo installer -pkg '$SCRIPT_DIR/${PKG_NAME}.pkg' -target /"
echo ""
echo "To upload to GitHub:"
echo "  gh release upload <tag> '$SCRIPT_DIR/${PKG_NAME}.pkg'"