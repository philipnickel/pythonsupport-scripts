#!/bin/bash
# Build script for DTU Python Stack using conda constructor
# Phase 1 implementation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/builds"
CONSTRUCT_FILE="$SCRIPT_DIR/construct.yaml"

echo "=== DTU Python Stack Constructor Build ==="
echo "Build script started at $(date)"
echo

# Check prerequisites
echo "Checking prerequisites..."

# Check if constructor is installed
if ! command -v constructor >/dev/null 2>&1; then
    echo " Constructor not found. Installing constructor..."
    if command -v conda >/dev/null 2>&1; then
        conda install -c conda-forge constructor -y
    else
        echo " Conda not found. Please install conda/miniconda first."
        exit 1
    fi
fi

echo " Constructor: $(constructor --version)"

# Check if construct.yaml exists
if [[ ! -f "$CONSTRUCT_FILE" ]]; then
    echo " construct.yaml not found at $CONSTRUCT_FILE"
    exit 1
fi

echo " Configuration file: $CONSTRUCT_FILE"

# Create builds directory
mkdir -p "$BUILD_DIR"
echo " Build directory: $BUILD_DIR"

# Create resources if they don't exist (placeholder for now)
mkdir -p "$SCRIPT_DIR/resources"

# Create placeholder resource files if they don't exist
if [[ ! -f "$SCRIPT_DIR/resources/LICENSE.txt" ]]; then
    cat > "$SCRIPT_DIR/resources/LICENSE.txt" << 'EOF'
DTU Python Stack
Educational software package for Technical University of Denmark

This package includes open-source Python libraries and DTU-specific tools
for mathematics and scientific computing education.

All included packages are subject to their respective licenses.
EOF
fi

if [[ ! -f "$SCRIPT_DIR/resources/README.txt" ]]; then
    cat > "$SCRIPT_DIR/resources/README.txt" << 'EOF'
DTU Python Stack

This installer provides a complete Python environment for DTU students including:
- Python 3.11
- Scientific computing packages (pandas, scipy, statsmodels, uncertainties)
- DTU-specific tools (dtumathtools)

After installation:
1. Open Terminal
2. Type 'python3' to start Python
3. Import any of the included packages

For support: Python Support Team
EOF
fi

echo " Resource files prepared"

# Clean any previous builds in the working directory
echo "Cleaning previous builds..."
rm -rf "$SCRIPT_DIR"/*.pkg "$SCRIPT_DIR"/build_* "$SCRIPT_DIR"/*.tar.bz2 2>/dev/null || true

# Run constructor
echo
echo "Building installer with constructor..."
echo "Configuration: $CONSTRUCT_FILE"
echo "Output directory: $BUILD_DIR"

# Change to script directory so constructor can find relative paths
cd "$SCRIPT_DIR"

# Run constructor (it will create the PKG in the current directory)
constructor . --output-dir="$BUILD_DIR"

# Check if build was successful
if [[ $? -eq 0 ]]; then
    echo
    echo " Build completed successfully!"
    echo
    echo "=== Build Results ==="
    ls -la "$BUILD_DIR"/*.sh 2>/dev/null || echo "No shell installer files found in $BUILD_DIR"
    ls -la "$SCRIPT_DIR"/*.sh 2>/dev/null || echo "No shell installer files found in $SCRIPT_DIR"
    
    # Find the generated installer file (.sh for shell, .pkg for PKG)
    INSTALLER_FILE=$(find "$BUILD_DIR" "$SCRIPT_DIR" -name "*.sh" -o -name "*.pkg" -type f 2>/dev/null | head -1)
    if [[ -n "$INSTALLER_FILE" ]]; then
        echo
        echo " Generated installer: $INSTALLER_FILE"
        echo "📁 Size: $(du -h "$INSTALLER_FILE" | cut -f1)"
        echo
        if [[ "$INSTALLER_FILE" == *.pkg ]]; then
            echo "=== Package Information ==="
            installer -pkginfo -pkg "$INSTALLER_FILE" 2>/dev/null || echo "Could not read package info"
            echo
            echo "=== Next Steps ==="
            echo "1. Test the installer: sudo installer -pkg '$INSTALLER_FILE' -target /"
            echo "2. Run the test script: ./test.sh '$INSTALLER_FILE'"
        else
            echo "=== Shell Installer Information ==="
            echo "Type: Shell installer (.sh)"
            echo "=== Next Steps ==="
            echo "1. Test the installer: bash '$INSTALLER_FILE' -b -p ~/miniconda3"
            echo "2. Run the test script: ./test.sh '$INSTALLER_FILE'"
        fi
        echo "3. Verify Python packages: python3 -c \"import dtumathtools, pandas, scipy, statsmodels, uncertainties\""
    else
        echo " No installer file found after build"
        exit 1
    fi
else
    echo " Constructor build failed"
    exit 1
fi

echo
echo "Build completed at $(date)"