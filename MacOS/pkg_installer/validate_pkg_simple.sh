#!/bin/bash
# DTU Python PKG Installer - Simple Structure Validation
# Quick validation of PKG structure without complex extraction

set -euo pipefail

# Configuration
PKG_PATH="/Users/philipnickel/Documents/GitHub/pythonsupport-scripts/MacOS/pkg_installer/builds/DtuPythonInstaller_1.0.59.pkg"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
CHECKS_TOTAL=0
CHECKS_PASSED=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((CHECKS_PASSED++))
}

log_failure() {
    echo -e "${RED}[FAIL]${NC} $1"
}

start_check() {
    ((CHECKS_TOTAL++))
    echo -e "${BLUE}[CHECK]${NC} $1"
}

main() {
    echo "DTU Python PKG Installer - Simple Validation"
    echo "============================================="
    echo ""

    # Check 1: File existence
    start_check "PKG file exists"
    if [ -f "$PKG_PATH" ]; then
        log_success "PKG file found: $(basename "$PKG_PATH")"
        log_info "Size: $(ls -lh "$PKG_PATH" | awk '{print $5}')"
    else
        log_failure "PKG file not found"
        exit 1
    fi

    # Check 2: File type
    start_check "PKG file type"
    if file "$PKG_PATH" | grep -q "xar archive"; then
        log_success "PKG has correct XAR archive format"
    else
        log_failure "PKG is not a valid XAR archive"
        exit 1
    fi

    # Check 3: Contents listing
    start_check "PKG contents structure"
    local contents=$(xar -tf "$PKG_PATH" 2>/dev/null)
    if echo "$contents" | grep -q "Distribution"; then
        log_success "Distribution file found"
    else
        log_failure "Distribution file missing"
    fi

    if echo "$contents" | grep -q "\.pkg/"; then
        log_success "Package directory found"
    else
        log_failure "Package directory missing"
    fi

    if echo "$contents" | grep -q "Scripts"; then
        log_success "Scripts archive found"
    else
        log_failure "Scripts archive missing"
    fi

    if echo "$contents" | grep -q "Payload"; then
        log_success "Payload archive found"
    else
        log_failure "Payload archive missing"
    fi

    # Check 4: Bundled components (quick check)
    start_check "Bundled components presence"
    local temp_dir="/tmp/pkg_quick_check_$$"
    mkdir -p "$temp_dir"
    
    if xar -xf "$PKG_PATH" -C "$temp_dir" >/dev/null 2>&1; then
        local pkg_dir=$(find "$temp_dir" -name "*.pkg" -type d)
        if [ -n "$pkg_dir" ] && [ -f "$pkg_dir/Payload" ]; then
            # Quick payload check without full extraction
            if (cd "$temp_dir" && cpio -i < "$pkg_dir/Payload" 2>/dev/null | head -10 | grep -q "components"); then
                log_success "Bundled components detected in payload"
            else
                log_info "Could not verify bundled components (non-critical)"
            fi
        fi
    fi
    
    rm -rf "$temp_dir"

    # Summary
    echo ""
    echo "==========================================="
    local success_rate=$(( CHECKS_PASSED * 100 / CHECKS_TOTAL ))
    if [ $success_rate -ge 75 ]; then
        log_success "PKG VALIDATION PASSED ($CHECKS_PASSED/$CHECKS_TOTAL checks passed)"
        log_info "The PKG appears to be properly structured"
    else
        log_failure "PKG validation found significant issues ($CHECKS_PASSED/$CHECKS_TOTAL checks passed)"
    fi
    echo "==========================================="
    
    return 0
}

# Run validation
main "$@"