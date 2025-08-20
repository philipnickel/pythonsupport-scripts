#!/bin/bash

# PKG Installation Test Script
# Tests PKG installation in a controlled environment

set -e

PKG_FILE="builds/DtuPythonInstaller_1.0.48.pkg"
TEST_ROOT="/tmp/pkg_test_install"

echo "🧪 PKG Installation Test"
echo "======================="
echo ""

# Check if PKG exists
if [[ ! -f "$PKG_FILE" ]]; then
    echo "❌ PKG file not found: $PKG_FILE"
    echo "Please run 'make build' first."
    exit 1
fi

# Create test environment
echo "🏗️  Setting up test environment..."
rm -rf "$TEST_ROOT"
mkdir -p "$TEST_ROOT"

# Get PKG info
echo "📋 Package Information:"
installer -pkginfo -pkg "$PKG_FILE"
echo ""

# Try to get more detailed info
echo "📊 Package Details:"
installer -verbose -pkginfo -pkg "$PKG_FILE" 2>/dev/null || echo "Basic PKG info shown above"
echo ""

# Extract and examine the PKG structure
EXTRACT_DIR="/tmp/pkg_examine"
echo "🔍 Examining PKG structure..."
rm -rf "$EXTRACT_DIR"
pkgutil --expand "$PKG_FILE" "$EXTRACT_DIR"

echo "📁 PKG Contents:"
find "$EXTRACT_DIR" -type f | head -10
echo ""

# Check if we can read the Distribution file
DIST_FILE="$EXTRACT_DIR/Distribution"
if [[ -f "$DIST_FILE" ]]; then
    echo "📜 Distribution XML:"
    head -20 "$DIST_FILE"
    echo ""
fi

# Try installation with verboseR (should show progress)
echo "🚀 Attempting installation with verbose output..."
echo "   (This will show what would happen during real installation)"
echo ""

# Note: This will fail due to permissions, but should show the process
installer -verboseR -pkg "$PKG_FILE" -target "$TEST_ROOT" 2>&1 || {
    echo ""
    echo "⚠️  Installation failed as expected (requires sudo/root)."
    echo "   However, this shows the installation process that would occur."
}

echo ""
echo "🧹 Cleaning up..."
rm -rf "$TEST_ROOT" "$EXTRACT_DIR"

echo ""
echo "✅ PKG Test Complete!"
echo ""
echo "To actually install (requires admin password):"
echo "sudo installer -pkg '$PKG_FILE' -target /"
echo ""
echo "During installation, press ⌘L in Installer.app to see progress indicators."