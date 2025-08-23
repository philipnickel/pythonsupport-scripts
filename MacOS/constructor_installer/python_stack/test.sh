#!/bin/bash
# Test script for DTU Python Stack constructor-generated PKG
# Phase 1 testing - adapts logic from test-pkg-installer.yml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_VERSION_EXPECTED="3.11"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test functions
log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Usage
usage() {
    echo "Usage: $0 [PKG_FILE]"
    echo "  PKG_FILE: Path to the DTU Python Stack PKG file to test"
    echo "  If not provided, will look for PKG in builds/ directory"
    exit 1
}

# Find PKG file
find_pkg_file() {
    if [[ $# -gt 0 && -f "$1" ]]; then
        echo "$1"
        return 0
    fi
    
    # Look in builds directory
    local pkg_file
    pkg_file=$(find "$SCRIPT_DIR/builds" -name "*.pkg" -type f 2>/dev/null | head -1)
    if [[ -n "$pkg_file" ]]; then
        echo "$pkg_file"
        return 0
    fi
    
    # Look in current directory
    pkg_file=$(find "$SCRIPT_DIR" -name "*.pkg" -type f 2>/dev/null | head -1)
    if [[ -n "$pkg_file" ]]; then
        echo "$pkg_file"
        return 0
    fi
    
    return 1
}

# Test system information
test_system_info() {
    log_info "=== System Information ==="
    sw_vers
    echo ""
    echo "=== Available Space ==="
    df -h / | head -2
    echo ""
    echo "=== Pre-test Environment ==="
    command -v conda >/dev/null 2>&1 && echo "✓ Conda: $(conda --version)" || echo "✗ Conda: Not installed"
    command -v python3 >/dev/null 2>&1 && echo "✓ Python3: $(python3 --version)" || echo "✗ Python3: Not installed"
    echo ""
}

# Install PKG
install_pkg() {
    local pkg_file="$1"
    
    log_info "=== Installing PKG ==="
    log_info "Package: $pkg_file"
    
    # Verify PKG file exists
    if [[ ! -f "$pkg_file" ]]; then
        log_error "PKG file not found: $pkg_file"
        return 1
    fi
    
    # Show package information
    log_info "Package Information:"
    installer -pkginfo -pkg "$pkg_file" || log_error "Could not read package info"
    
    # Install the PKG
    log_info "Installing PKG (requires sudo)..."
    if sudo installer -verbose -pkg "$pkg_file" -target /; then
        log_success "PKG installation completed"
    else
        log_error "PKG installation failed"
        return 1
    fi
}

# Verify installation
verify_installation() {
    log_info "=== Post-Installation Verification ==="
    
    # Update shell environment
    hash -r 2>/dev/null || true
    
    # Initialize conda if available
    local conda_initialized=false
    for conda_path in "/opt/homebrew/Caskroom/miniconda/base" "/usr/local/Caskroom/miniconda/base" "$HOME/miniconda3" "$HOME/anaconda3"; do
        if [[ -f "$conda_path/etc/profile.d/conda.sh" ]]; then
            source "$conda_path/etc/profile.d/conda.sh"
            conda activate base 2>/dev/null || true
            conda_initialized=true
            log_success "Conda environment initialized from $conda_path"
            break
        fi
    done
    
    if [[ "$conda_initialized" == false ]]; then
        log_error "Could not initialize conda environment"
    fi
    
    # Check conda
    log_info "Checking Conda..."
    if command -v conda >/dev/null 2>&1; then
        log_success "Conda: $(conda --version)"
        log_success "Conda location: $(which conda)"
        log_success "Conda base: $(conda info --base)"
    else
        log_error "Conda: Not found in PATH"
        return 1
    fi
    
    # Check Python
    log_info "Checking Python..."
    if command -v python3 >/dev/null 2>&1; then
        local python_version
        python_version=$(python3 --version | cut -d " " -f 2)
        log_success "Python3: $python_version"
        log_success "Python location: $(which python3)"
        
        # Verify Python version matches expected
        if [[ "$python_version" == "$PYTHON_VERSION_EXPECTED"* ]]; then
            log_success "Python version matches expected ($PYTHON_VERSION_EXPECTED)"
        else
            log_error "Python version ($python_version) does not match expected ($PYTHON_VERSION_EXPECTED)"
            return 1
        fi
    else
        log_error "Python3: Not found in PATH"
        return 1
    fi
    
    # Test package imports (exact same test as existing workflow)
    log_info "Testing Python package imports..."
    if python3 -c "import dtumathtools, pandas, scipy, statsmodels, uncertainties; print('Packages imported successfully')" >/dev/null 2>&1; then
        log_success "All required packages imported successfully"
    else
        log_error "Failed to import Python packages"
        log_info "Testing individual package imports for debugging..."
        
        for pkg in dtumathtools pandas scipy statsmodels uncertainties; do
            if python3 -c "import $pkg; print('✓ $pkg')" 2>/dev/null; then
                log_success "$pkg: Available"
            else
                log_error "$pkg: Failed to import"
            fi
        done
        return 1
    fi
    
    # Test basic functionality
    log_info "Testing basic Python functionality..."
    if python3 -c "import numpy as np; import pandas as pd; print('NumPy version:', np.__version__); print('Pandas version:', pd.__version__)" 2>/dev/null; then
        log_success "Basic scientific computing functionality verified"
    else
        log_error "Basic functionality test failed"
    fi
}

# Main test function
run_tests() {
    local pkg_file="$1"
    local overall_success=true
    
    echo "=== DTU Python Stack PKG Test Suite ==="
    echo "Package: $pkg_file"
    echo "Test started: $(date)"
    echo ""
    
    # Run test phases
    test_system_info || overall_success=false
    install_pkg "$pkg_file" || overall_success=false
    verify_installation || overall_success=false
    
    echo ""
    echo "=== Test Summary ==="
    if [[ "$overall_success" == true ]]; then
        log_success "🎉 All tests passed! DTU Python Stack is working correctly."
        log_info "Test completed: $(date)"
        return 0
    else
        log_error "❌ Some tests failed. Please check the output above."
        log_info "Test completed: $(date)"
        return 1
    fi
}

# Main script
main() {
    # Handle command line arguments
    local pkg_file
    if ! pkg_file=$(find_pkg_file "$@"); then
        log_error "Could not find PKG file"
        echo "Available files:"
        ls -la "$SCRIPT_DIR"/builds/*.pkg 2>/dev/null || echo "No PKG files in builds/"
        ls -la "$SCRIPT_DIR"/*.pkg 2>/dev/null || echo "No PKG files in current directory"
        usage
    fi
    
    log_info "Using PKG file: $pkg_file"
    
    # Run the tests
    run_tests "$pkg_file"
}

# Execute main function with all arguments
main "$@"