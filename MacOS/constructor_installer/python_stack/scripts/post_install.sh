#!/bin/bash
# Post-install script for DTU Python Stack
# Handles Python environment setup and basic configuration

set -eo pipefail

# Logging functions
log_info() {
    echo "[INFO] $*"
}

log_success() {
    echo "[SUCCESS] $*"
}

log_warning() {
    echo "[WARNING] $*"
}

log_info "Starting DTU Python Development Environment post-install..."

# =============================================================================
# Phase 1: Python Environment Setup
# =============================================================================

log_info "Configuring Python environment..."

# Basic conda configuration
conda config --set anaconda_anon_usage off 2>/dev/null || log_warning "Could not set anaconda_anon_usage"
conda config --set auto_activate_base true 2>/dev/null || log_warning "Could not set auto_activate_base"

# Shell integration
conda init bash 2>/dev/null || log_warning "Could not init bash"
conda init zsh 2>/dev/null || log_warning "Could not init zsh"

log_success "Python environment configured"

# =============================================================================
# Installation Complete
# =============================================================================

log_success " DTU Python Stack installation completed!"
log_info ""
log_info "=== Installation Summary ==="
log_info "✓ Python 3.11 with scientific packages (pandas, scipy, statsmodels, uncertainties, dtumathtools)"
log_info "✓ Conda environment activated and shell integration configured"
log_info ""
log_info "=== Next Steps ==="
log_info "1. Restart your terminal or run: source ~/.bash_profile (or ~/.zshrc)"
log_info "2. Test Python: python3 -c \"import pandas, dtumathtools; print('Success!')\""
log_info "3. Refer to your course materials for usage guidance"
log_info ""
log_info "Need help? Visit: https://pythonsupport.dtu.dk"
log_info ""

exit 0