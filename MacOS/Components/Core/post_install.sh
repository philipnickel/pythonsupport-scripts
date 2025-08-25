#!/bin/bash
# @doc
# @name: Post-Installation Verification Script
# @description: Verifies installation success and generates diagnostic report
# @category: Core
# @usage: ./post_install.sh
# @requirements: macOS system, completed installation
# @notes: Should be run after installation to verify and report results
# @/doc

# Set strict error handling
set -e

# Load utilities
if ! eval "$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared/common.sh")"; then
    echo "ERROR: Failed to load utilities from remote repository"
    exit 1
fi

log_info "DTU Python Support - Post-Installation Verification"
log_info "==================================================="

# Variables for tracking verification results
VERIFICATION_PASSED=true
PYTHON_VERIFIED=false
VSCODE_VERIFIED=false
PYTHON_PACKAGES_VERIFIED=false
VSCODE_EXTENSIONS_VERIFIED=false

# Verify Python 3.11 installation
verify_python_installation() {
    log_info "Verifying Python 3.11 installation..."
    
    if command -v python3 >/dev/null 2>&1; then
        local python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
        log_info "Found Python: $python_version"
        
        if echo "$python_version" | grep -q "^3\.11\."; then
            PYTHON_VERIFIED=true
            log_success "Python 3.11 installation verified"
        else
            log_warning "Python version mismatch: found $python_version, expected 3.11.x"
            VERIFICATION_PASSED=false
        fi
    else
        log_error "Python 3 not found in PATH"
        VERIFICATION_PASSED=false
    fi
}

# Verify required Python packages
verify_python_packages() {
    if [ "$PYTHON_VERIFIED" = true ]; then
        log_info "Verifying required Python packages..."
        
        local required_packages=("dtumathtools" "pandas" "scipy" "statsmodels" "uncertainties")
        local verified_packages=()
        local missing_packages=()
        
        for package in "${required_packages[@]}"; do
            if python3 -c "import $package" 2>/dev/null; then
                verified_packages+=("$package")
                log_info "✓ $package"
            else
                missing_packages+=("$package")
                log_info "✗ $package"
            fi
        done
        
        if [ ${#missing_packages[@]} -eq 0 ]; then
            PYTHON_PACKAGES_VERIFIED=true
            log_success "All required Python packages verified"
        else
            log_warning "Missing Python packages: ${missing_packages[*]}"
            VERIFICATION_PASSED=false
        fi
    else
        log_warning "Skipping package verification - Python not verified"
    fi
}

# Verify Visual Studio Code installation
verify_vscode_installation() {
    log_info "Verifying Visual Studio Code installation..."
    
    if command -v code >/dev/null 2>&1; then
        local vscode_version=$(code --version 2>/dev/null | head -1)
        log_info "Found VS Code: $vscode_version"
        
        VSCODE_VERIFIED=true
        log_success "Visual Studio Code installation verified"
    else
        log_error "Visual Studio Code 'code' command not found in PATH"
        VERIFICATION_PASSED=false
    fi
}

# Verify VS Code Python extension
verify_vscode_extensions() {
    if [ "$VSCODE_VERIFIED" = true ]; then
        log_info "Verifying VS Code Python extension..."
        
        if code --list-extensions 2>/dev/null | grep -q "ms-python.python"; then
            VSCODE_EXTENSIONS_VERIFIED=true
            log_success "VS Code Python extension verified"
        else
            log_warning "VS Code Python extension not installed"
            VERIFICATION_PASSED=false
        fi
    else
        log_warning "Skipping extension verification - VS Code not verified"
    fi
}

# Run comprehensive diagnostics
run_diagnostics() {
    log_info "Running comprehensive diagnostics..."
    
    # Set environment variable for the diagnostics script to use our install log
    export INSTALL_LOG="${INSTALL_LOG:-/tmp/dtu_install_latest.log}"
    
    log_info "Generating diagnostic report..."
    if INSTALL_LOG="$INSTALL_LOG" REMOTE_PS="${REMOTE_PS}" BRANCH_PS="${BRANCH_PS}" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Diagnostics/simple_report.sh)"; then
        log_success "Diagnostic report generated successfully"
        return 0
    else
        log_warning "Diagnostic report generation failed"
        return 1
    fi
}

# Generate verification summary
generate_summary() {
    echo ""
    log_info "Post-Installation Summary"
    log_info "========================="
    
    echo "Installation Verification Results:"
    
    if [ "$PYTHON_VERIFIED" = true ]; then
        echo "  Python 3.11: ✓ Verified"
    else
        echo "  Python 3.11: ✗ Failed"
    fi
    
    if [ "$PYTHON_PACKAGES_VERIFIED" = true ]; then
        echo "  Python packages: ✓ Verified"
    else
        echo "  Python packages: ✗ Failed"
    fi
    
    if [ "$VSCODE_VERIFIED" = true ]; then
        echo "  VS Code: ✓ Verified"
    else
        echo "  VS Code: ✗ Failed"
    fi
    
    if [ "$VSCODE_EXTENSIONS_VERIFIED" = true ]; then
        echo "  Python extension: ✓ Verified"
    else
        echo "  Python extension: ✗ Failed"
    fi
    
    echo ""
    
    if [ "$VERIFICATION_PASSED" = true ]; then
        log_success "Installation verification PASSED - DTU first-year setup is complete!"
    else
        log_error "Installation verification FAILED - Setup incomplete"
    fi
}

# Main execution
main() {
    echo "DTU Python Support - Post-Installation Verification"
    echo "===================================================="
    echo ""
    
    # Run all verification steps
    verify_python_installation
    verify_python_packages
    verify_vscode_installation
    verify_vscode_extensions
    
    # Generate summary
    generate_summary
    
    # Run diagnostics
    echo ""
    log_info "Running diagnostic report generation..."
    if run_diagnostics; then
        log_success "Diagnostic report completed successfully"
    else
        log_warning "Diagnostic report generation failed, continuing anyway"
    fi
    
    # Final result
    echo ""
    if [ "$VERIFICATION_PASSED" = true ]; then
        echo "🎉 Congratulations! Your DTU first-year Python setup is ready."
        echo "You can now:"
        echo "  • Open VS Code by running: code"
        echo "  • Start coding with Python 3.11 and all required packages"
        echo "  • Access dtumathtools for your mathematics courses"
        echo ""
        echo "Need help? Visit: https://pythonsupport.dtu.dk"
        echo "Questions? Email: pythonsupport@dtu.dk"
        echo ""
        log_success "Post-installation verification completed successfully"
        return 0
    else
        echo "Installation was not completed successfully."
        echo "Please visit: https://pythonsupport.dtu.dk/install/macos/automated-error.html"
        echo "Or contact: pythonsupport@dtu.dk for assistance"
        echo ""
        log_error "Post-installation verification failed"
        return 1
    fi
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi