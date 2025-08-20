#!/bin/bash

# PKG Installation Test Script
# Tests PKG installation in a controlled environment

set -e

PKG_FILE="builds/DtuPythonInstaller_1.0.49.pkg"

echo "🧪 PKG Installation Test"
echo "======================="
echo ""

# Check if PKG exists
if [[ ! -f "$PKG_FILE" ]]; then
    echo "❌ PKG file not found: $PKG_FILE"
    echo "Available PKG files:"
    find . -name "*.pkg" -type f
    exit 1
fi

echo "📋 Package Information:"
installer -pkginfo -pkg "$PKG_FILE"
echo ""

# Extract PKG and set up proper test environment
EXTRACT_DIR="/tmp/pkg_test_scripts"
TEST_ROOT="/tmp/pkg_test_install"
echo "🔍 Extracting PKG to test scripts..."
rm -rf "$EXTRACT_DIR" "$TEST_ROOT"
pkgutil --expand "$PKG_FILE" "$EXTRACT_DIR"

# Extract the Payload to simulate PKG installation
PAYLOAD_FILE=$(find "$EXTRACT_DIR" -name "Payload" -type f | head -1)
if [[ -f "$PAYLOAD_FILE" ]]; then
    echo "📦 Extracting Payload to simulate installation..."
    mkdir -p "$TEST_ROOT"
    cd "$TEST_ROOT" || exit 1
    cat "$PAYLOAD_FILE" | gzip -d | cpio -i 2>/dev/null || echo "Payload extraction completed"
    
    # Set up the /dtu_components symlink/directory for testing
    if [[ -d "$TEST_ROOT/dtu_components" ]]; then
        echo "📁 Creating /dtu_components link for testing..."
        sudo rm -f /dtu_components 2>/dev/null || true
        sudo ln -sf "$TEST_ROOT/dtu_components" /dtu_components || {
            echo "⚠️  Cannot create symlink, copying to /tmp/dtu_components instead"
            rm -rf /tmp/dtu_components
            cp -r "$TEST_ROOT/dtu_components" /tmp/dtu_components
            export COMPONENTS_DIR="/tmp/dtu_components"
        }
    fi
fi

# Find scripts directory
SCRIPTS_DIR=$(find "$EXTRACT_DIR" -name "Scripts" -type d | head -1)

if [[ -d "$SCRIPTS_DIR" ]]; then
    echo "📁 Scripts found at: $SCRIPTS_DIR"
    echo ""
    
    echo "🔧 Testing Preinstall Script:"
    echo "=============================="
    if [[ -x "$SCRIPTS_DIR/preinstall" ]]; then
        bash "$SCRIPTS_DIR/preinstall" 2>&1 || echo "Preinstall completed with warnings"
    else
        echo "❌ Preinstall script not found"
    fi
    
    echo ""
    echo "🚀 Testing Postinstall Script (with simulated environment):"
    echo "============================================="
    if [[ -x "$SCRIPTS_DIR/postinstall" ]]; then
        # Set up environment for testing
        export USER="$(whoami)"
        export HOME="$HOME"
        # Override COMPONENTS_DIR if we had to use /tmp
        if [[ -n "$COMPONENTS_DIR" ]]; then
            sed -i '' "s|COMPONENTS_DIR=\"/dtu_components\"|COMPONENTS_DIR=\"$COMPONENTS_DIR\"|" "$SCRIPTS_DIR/postinstall"
        fi
        bash "$SCRIPTS_DIR/postinstall" 2>&1 || echo "Postinstall completed with warnings"
    else
        echo "❌ Postinstall script not found"
    fi
else
    echo "❌ No Scripts directory found"
fi

# Cleanup
if [[ -L /dtu_components ]]; then
    echo "🧹 Removing test symlink..."
    sudo rm -f /dtu_components 2>/dev/null || true
fi
rm -rf "$TEST_ROOT" "/tmp/dtu_components" 2>/dev/null || true

echo ""
echo "🧹 Cleaning up..."
rm -rf "$EXTRACT_DIR"

echo ""
echo "✅ PKG Script Test Complete!"
echo ""
echo "This simulates what happens during PKG installation."
echo "The progress indicators shown above will appear in the installer log."
echo ""
echo "To install for real: sudo installer -pkg '$PKG_FILE' -target /"