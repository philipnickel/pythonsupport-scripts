#!/bin/bash
# @doc
# @name: Post-Installation Verification Script
# @description: Verifies installation success, performs Piwik analytics reporting, and generates diagnostics
# @category: Core
# @usage: ./post_install.sh
# @requirements: macOS system, completed installation
# @notes: Should be run after installation to verify and report results
# @/doc

# Set strict error handling
set -e

# Load simple utilities - use remote loading for compatibility when run via curl
if ! eval "$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-philipnickel/pythonsupport-scripts}/${BRANCH_PS:-Miniforge}/MacOS/Components/Shared/simple_utils.sh")"; then
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
VERIFICATION_ERRORS=()
VERIFICATION_WARNINGS=()

# Load pre-installation findings if available
load_pre_install_findings() {
    if [ -f "/tmp/dtu_pre_install_findings.env" ]; then
        log_info "Loading pre-installation findings..."
        source "/tmp/dtu_pre_install_findings.env"
    else
        log_warning "Pre-installation findings not found. Skipping comparison."
    fi
}

# Verify Python 3.11 installation
verify_python_installation() {
    log_info "Verifying Python 3.11 installation..."
    
    if command -v python3 >/dev/null 2>&1; then
        local python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
        log_info "Found Python: $python_version"
        
        if echo "$python_version" | grep -q "^3\.11\."; then
            PYTHON_VERIFIED=true
            log_success "Python 3.11 installation verified"
            
            # Track analytics for successful Python installation
            piwik_log "python_verification_success" echo "Python 3.11 verified: $python_version"
        else
            VERIFICATION_ERRORS+=("Python version mismatch: found $python_version, expected 3.11.x")
            VERIFICATION_PASSED=false
            piwik_log "python_verification_failure" echo "Python version mismatch: $python_version"
        fi
    else
        VERIFICATION_ERRORS+=("Python 3 not found in PATH")
        VERIFICATION_PASSED=false
        piwik_log "python_verification_failure" echo "Python 3 not found"
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
            piwik_log "python_packages_verification_success" echo "All packages verified: ${verified_packages[*]}"
        else
            VERIFICATION_ERRORS+=("Missing Python packages: ${missing_packages[*]}")
            VERIFICATION_PASSED=false
            piwik_log "python_packages_verification_failure" echo "Missing packages: ${missing_packages[*]}"
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
        
        # Track analytics for successful VS Code installation
        piwik_log "vscode_verification_success" echo "VS Code verified: $vscode_version"
    else
        VERIFICATION_ERRORS+=("Visual Studio Code 'code' command not found in PATH")
        VERIFICATION_PASSED=false
        piwik_log "vscode_verification_failure" echo "VS Code command not found"
    fi
}

# Verify VS Code Python extension
verify_vscode_extensions() {
    if [ "$VSCODE_VERIFIED" = true ]; then
        log_info "Verifying VS Code Python extension..."
        
        if code --list-extensions 2>/dev/null | grep -q "ms-python.python"; then
            VSCODE_EXTENSIONS_VERIFIED=true
            log_success "VS Code Python extension verified"
            piwik_log "vscode_extensions_verification_success" echo "Python extension verified"
        else
            VERIFICATION_ERRORS+=("VS Code Python extension not installed")
            VERIFICATION_PASSED=false
            piwik_log "vscode_extensions_verification_failure" echo "Python extension not found"
        fi
    else
        log_warning "Skipping extension verification - VS Code not verified"
    fi
}

# Run comprehensive diagnostics
run_diagnostics() {
    log_info "Running comprehensive diagnostics..."
    
    local diagnostics_script="$SCRIPT_DIR/../Diagnostics/simple_report.sh"
    
    if [ -f "$diagnostics_script" ]; then
        # Set environment variable for the diagnostics script to use our install log
        export INSTALL_LOG="${INSTALL_LOG:-/tmp/dtu_install_latest.log}"
        
        log_info "Generating diagnostic report..."
        if INSTALL_LOG="$INSTALL_LOG" piwik_log "diagnostics_generation" "$diagnostics_script"; then
            log_success "Diagnostic report generated successfully"
            return 0
        else
            VERIFICATION_WARNINGS+=("Diagnostic report generation failed")
            return 1
        fi
    else
        VERIFICATION_WARNINGS+=("Diagnostic script not found at $diagnostics_script")
        return 1
    fi
}

# Generate verification summary report
generate_verification_summary() {
    echo ""
    log_info "Post-Installation Verification Summary"
    log_info "======================================"
    
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
    
    # Show warnings
    if [ ${#VERIFICATION_WARNINGS[@]} -gt 0 ]; then
        echo ""
        echo "Warnings:"
        for warning in "${VERIFICATION_WARNINGS[@]}"; do
            echo "  ⚠  $warning"
        done
    fi
    
    # Show errors
    if [ ${#VERIFICATION_ERRORS[@]} -gt 0 ]; then
        echo ""
        echo "Verification Errors:"
        for error in "${VERIFICATION_ERRORS[@]}"; do
            echo "  ✗ $error"
        done
    fi
    
    echo ""
    
    # Overall result
    if [ "$VERIFICATION_PASSED" = true ]; then
        log_success "Installation verification PASSED - DTU first-year setup is complete!"
        piwik_log "overall_installation_success" echo "Complete installation verified successfully"
        
        echo ""
        echo "🎉 Congratulations! Your DTU first-year Python setup is ready."
        echo "You can now:"
        echo "  • Open VS Code by running: code"
        echo "  • Start coding with Python 3.11 and all required packages"
        echo "  • Access dtumathtools for your mathematics courses"
        echo ""
        echo "Need help? Visit: https://pythonsupport.dtu.dk"
        echo "Questions? Email: pythonsupport@dtu.dk"
        
        return 0
    else
        log_error "Installation verification FAILED - Setup incomplete"
        piwik_log "overall_installation_failure" echo "Installation verification failed: ${#VERIFICATION_ERRORS[@]} errors"
        
        echo ""
        echo "Installation was not completed successfully."
        echo "Please visit: https://pythonsupport.dtu.dk/install/macos/automated-error.html"
        echo "Or contact: pythonsupport@dtu.dk for assistance"
        
        return 1
    fi
}

# Compare with pre-installation state
compare_with_pre_install() {
    if [ -f "/tmp/dtu_pre_install_findings.env" ]; then
        echo ""
        log_info "Installation Changes Summary"
        log_info "============================"
        
        # Compare Python installation
        if [ "$PYTHON_FOUND" != "true" ] && [ "$PYTHON_VERIFIED" = true ]; then
            echo "  ✓ Python 3.11 - NEWLY INSTALLED"
        elif [ "$PYTHON_FOUND" = "true" ] && [ "$PYTHON_VERIFIED" = true ]; then
            echo "  ✓ Python 3.11 - VERIFIED (was already present)"
        fi
        
        # Compare VS Code installation
        if [ "$VSCODE_FOUND" != "true" ] && [ "$VSCODE_VERIFIED" = true ]; then
            echo "  ✓ VS Code - NEWLY INSTALLED"
        elif [ "$VSCODE_FOUND" = "true" ] && [ "$VSCODE_VERIFIED" = true ]; then
            echo "  ✓ VS Code - VERIFIED (was already present)"
        fi
        
        # Compare packages
        if [ "$PYTHON_PACKAGES_FOUND" != "true" ] && [ "$PYTHON_PACKAGES_VERIFIED" = true ]; then
            echo "  ✓ Python packages - NEWLY INSTALLED"
        elif [ "$PYTHON_PACKAGES_FOUND" = "true" ] && [ "$PYTHON_PACKAGES_VERIFIED" = true ]; then
            echo "  ✓ Python packages - VERIFIED (were already present)"
        fi
        
        # Compare extensions
        if [ "$VSCODE_EXTENSIONS_FOUND" != "true" ] && [ "$VSCODE_EXTENSIONS_VERIFIED" = true ]; then
            echo "  ✓ Python extension - NEWLY INSTALLED"
        elif [ "$VSCODE_EXTENSIONS_FOUND" = "true" ] && [ "$VSCODE_EXTENSIONS_VERIFIED" = true ]; then
            echo "  ✓ Python extension - VERIFIED (was already present)"
        fi
    fi
}

# Clean up temporary files
cleanup() {
    log_info "Cleaning up temporary files..."
    
    # Remove pre-installation findings (but keep for debugging if verification failed)
    if [ "$VERIFICATION_PASSED" = true ]; then
        rm -f "/tmp/dtu_pre_install_findings.env"
    else
        log_info "Keeping pre-installation findings for debugging"
    fi
}

# Send final analytics report
send_final_analytics() {
    log_info "Sending final analytics report..."
    
    local total_components=4
    local verified_components=0
    
    [ "$PYTHON_VERIFIED" = true ] && verified_components=$((verified_components + 1))
    [ "$PYTHON_PACKAGES_VERIFIED" = true ] && verified_components=$((verified_components + 1))
    [ "$VSCODE_VERIFIED" = true ] && verified_components=$((verified_components + 1))
    [ "$VSCODE_EXTENSIONS_VERIFIED" = true ] && verified_components=$((verified_components + 1))
    
    local success_rate=$((verified_components * 100 / total_components))
    
    if [ "$VERIFICATION_PASSED" = true ]; then
        piwik_log "post_install_verification_complete" echo "Verification completed: ${verified_components}/${total_components} components (${success_rate}%)"
    else
        piwik_log "post_install_verification_incomplete" echo "Verification incomplete: ${verified_components}/${total_components} components (${success_rate}%)"
    fi
}

# Main execution
main() {
    echo "DTU Python Support - Post-Installation Verification"
    echo "===================================================="
    echo ""
    
    # Load pre-installation findings for comparison
    load_pre_install_findings
    
    # Run all verification steps
    verify_python_installation
    verify_python_packages
    verify_vscode_installation
    verify_vscode_extensions
    
    # Generate and show summary
    if generate_verification_summary; then
        compare_with_pre_install
        
        # Run diagnostics (optional - don't fail if it doesn't work)
        echo ""
        run_diagnostics || true
        
        # Send final analytics
        send_final_analytics
        
        # Cleanup
        cleanup
        
        echo ""
        log_success "Post-installation verification completed successfully"
        return 0
    else
        send_final_analytics
        log_error "Post-installation verification failed"
        return 1
    fi
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi