#!/bin/bash

# Build script for DTU Python Environment using Constructor

set -e

echo "Building DTU Python Environment with Constructor..."

# Check if constructor is installed
if ! command -v constructor >/dev/null 2>&1; then
    echo "Installing Constructor..."
    conda install -c conda-forge constructor -y
fi

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf build/ dist/

# Build the installer
echo "Building installer..."
constructor --platform osx-64 .

echo "Build complete!"
echo "Installer created in: dist/"
ls -la dist/
