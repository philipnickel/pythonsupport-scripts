#!/bin/bash
# Build script for DTU Python Stack using conda constructor

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/builds"

echo "=== DTU Python Stack Constructor Build ==="

# Check if constructor is installed
if ! command -v constructor >/dev/null 2>&1; then
    echo "Installing constructor..."
    conda install -c conda-forge constructor -y
fi

echo "Constructor: $(constructor --version)"

# Create builds directory
mkdir -p "$BUILD_DIR"

# Clean previous builds
rm -rf "$BUILD_DIR"/*.pkg 2>/dev/null || true

# Run constructor
echo "Building installer..."
cd "$SCRIPT_DIR"
constructor . --output-dir="$BUILD_DIR"

# Check results
if ls "$BUILD_DIR"/*.pkg >/dev/null 2>&1; then
    PKG_FILE=$(ls "$BUILD_DIR"/*.pkg | head -1)
    echo "Build completed successfully!"
    echo "Generated: $(basename "$PKG_FILE")"
    echo "Size: $(du -h "$PKG_FILE" | cut -f1)"
else
    echo "Build failed - no PKG file generated"
    exit 1
fi