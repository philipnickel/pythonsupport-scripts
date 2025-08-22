#!/bin/bash
# Minimal PKG Test Build Script
# Tests basic pre/postinstall functionality with RTF files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build_test"
PKG_NAME="DTU_Test_PKG"
VERSION="1.0.0"

echo "Building minimal test PKG with RTF files..."
echo "Version: $VERSION"
echo ""

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Create component package
echo "Creating component package..."
pkgbuild \
    --nopayload \
    --scripts "$SCRIPT_DIR/Scripts" \
    --identifier "dk.dtu.test-pkg" \
    --version "$VERSION" \
    --install-location "/tmp" \
    "$BUILD_DIR/${PKG_NAME}-component.pkg"

# Create distribution package with RTF files
echo "Creating distribution package with RTF files..."
productbuild \
    --distribution "$SCRIPT_DIR/distribution.xml" \
    --resources "$SCRIPT_DIR/Resources" \
    --package-path "$BUILD_DIR" \
    "$BUILD_DIR/${PKG_NAME}.pkg"

echo ""
echo "✅ Test PKG built successfully: $BUILD_DIR/${PKG_NAME}.pkg"
echo ""
echo "To test locally:"
echo "  sudo installer -pkg '$BUILD_DIR/${PKG_NAME}.pkg' -target /"
echo ""
echo "After installation, check:"
echo "  cat /tmp/dtu_preinstall.log"
echo "  cat /tmp/dtu_postinstall.log"
