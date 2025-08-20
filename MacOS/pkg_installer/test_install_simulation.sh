#!/bin/bash

# Test Installation Simulation
# This simulates what happens during PKG installation without requiring sudo

set -e

echo "🧪 DTU Python PKG Installer - Installation Simulation"
echo "======================================================"
echo ""
echo "This simulates the PKG installation process to test our progress indicators."
echo "Press Ctrl+C to cancel at any time."
echo ""

# Extract PKG to test the scripts
PKG_FILE="builds/DtuPythonInstaller_1.0.46.pkg"
TEST_DIR="/tmp/pkg_install_test"

if [[ ! -f "$PKG_FILE" ]]; then
    echo "❌ PKG file not found: $PKG_FILE"
    echo "Please run 'make build' first."
    exit 1
fi

echo "📦 Extracting PKG for testing..."
rm -rf "$TEST_DIR"
pkgutil --expand "$PKG_FILE" "$TEST_DIR"

# Find the scripts
SCRIPTS_DIR=$(find "$TEST_DIR" -name "Scripts" -type d | head -1)

if [[ ! -d "$SCRIPTS_DIR" ]]; then
    echo "❌ Scripts directory not found in PKG"
    echo "Available directories:"
    find "$TEST_DIR" -type d
    exit 1
fi

echo "📁 Scripts found at: $SCRIPTS_DIR"
echo ""

# Test preinstall script
echo "🔧 Running Pre-installation Checks..."
echo "======================================"
if [[ -x "$SCRIPTS_DIR/preinstall" ]]; then
    bash "$SCRIPTS_DIR/preinstall" || echo "Pre-install completed with warnings"
else
    echo "❌ Preinstall script not found or not executable"
fi

echo ""
echo "🚀 Running Main Installation..."
echo "==============================="

# Test postinstall script
if [[ -x "$SCRIPTS_DIR/postinstall" ]]; then
    # Set up environment for postinstall script
    export USER="$(whoami)"
    export HOME="$HOME"
    
    # Run postinstall script
    bash "$SCRIPTS_DIR/postinstall" || echo "Post-install completed with warnings"
else
    echo "❌ Postinstall script not found or not executable"
fi

# Cleanup
echo ""
echo "🧹 Cleaning up test files..."
rm -rf "$TEST_DIR"

echo ""
echo "✅ Installation simulation complete!"
echo ""
echo "This demonstrates what users will see during real PKG installation."
echo "During actual PKG installation, press ⌘L in Installer.app to view these progress messages."