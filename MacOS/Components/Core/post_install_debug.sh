#!/bin/bash
# Debug version of post_install to identify hanging issue

# Load utilities
if ! eval "$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared/common.sh")"; then
    echo "ERROR: Failed to load utilities from remote repository"
    exit 1
fi

log_info "DTU Python Support - Post-Installation Verification (DEBUG)"
log_info "====================================================="

log_info "Starting verification functions..."

# Verify Python 3.11 installation
verify_python_installation() {
    log_info "Verifying Python 3.11 installation..."
    
    if command -v python3 >/dev/null 2>&1; then
        local python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
        log_info "Found Python: $python_version"
        
        if echo "$python_version" | grep -q "^3\.11\."; then
            log_success "Python 3.11 installation verified"
        else
            log_warning "Python version mismatch: found $python_version, expected 3.11.x"
        fi
    else
        log_error "Python 3 not found in PATH"
    fi
}

# Run diagnostics
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

log_info "Testing Python verification..."
verify_python_installation

log_info "Testing diagnostic generation..."
if run_diagnostics; then
    log_success "Diagnostics completed"
else
    log_warning "Diagnostics failed"
fi

log_success "Debug test completed!"