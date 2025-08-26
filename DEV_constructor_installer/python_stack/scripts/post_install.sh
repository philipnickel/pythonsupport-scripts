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

# Remove default channels to avoid commercial channel warnings
conda config --remove channels defaults 2>/dev/null || log_warning "Could not remove defaults channel"
conda config --add channels conda-forge 2>/dev/null || log_warning "Could not add conda-forge channel"

# Shell integration
conda init bash 2>/dev/null || log_warning "Could not init bash"
conda init zsh 2>/dev/null || log_warning "Could not init zsh"

log_success "Python environment configured"

# =============================================================================
# Phase 2: VS Code Installation
# =============================================================================

log_info "Installing Visual Studio Code..."

VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=darwin-universal"
VSCODE_ZIP="/tmp/vscode.zip"
VSCODE_APP="/Applications/Visual Studio Code.app"

# Check if already installed
if [ -d "$VSCODE_APP" ]; then
    log_info "VS Code already installed"
else
    log_info "Downloading VS Code..."
    if curl -fsSL -o "$VSCODE_ZIP" "$VSCODE_URL" 2>/dev/null; then
        log_info "Extracting VS Code..."
        if unzip -q "$VSCODE_ZIP" -d /tmp/ 2>/dev/null; then
            log_info "Installing VS Code..."
            if mv "/tmp/Visual Studio Code.app" "$VSCODE_APP" 2>/dev/null; then
                log_success "VS Code installed successfully"
            else
                log_warning "Could not move VS Code to Applications (continuing anyway)"
            fi
        else
            log_warning "Could not extract VS Code ZIP (continuing anyway)"
        fi
        rm -f "$VSCODE_ZIP" 2>/dev/null
    else
        log_warning "Could not download VS Code (continuing anyway)"
    fi
fi

# =============================================================================
# Phase 3: VS Code CLI Setup
# =============================================================================

log_info "Setting up VS Code CLI..."

if [ -d "$VSCODE_APP" ]; then
    # Try to set up CLI without sudo first, fallback gracefully
    VSCODE_BINARY="$VSCODE_APP/Contents/Resources/app/bin/code"
    if [ -f "$VSCODE_BINARY" ]; then
        # Just add to PATH in shell profiles instead of system-wide symlink
        for profile in "$HOME/.bash_profile" "$HOME/.zshrc"; do
            if [ -f "$profile" ] && ! grep -q "Visual Studio Code" "$profile"; then
                echo '# VS Code CLI' >> "$profile"
                echo 'export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"' >> "$profile"
            fi
        done
        log_success "VS Code CLI configured in shell profiles"
    fi
fi

# =============================================================================
# Phase 4: VS Code Extensions
# =============================================================================

log_info "Installing VS Code extensions..."

if [ -d "$VSCODE_APP" ]; then
    # Export PATH temporarily for this script
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
    
    if command -v code >/dev/null 2>&1; then
        EXTENSIONS=("ms-python.python" "ms-toolsai.jupyter")
        for ext in "${EXTENSIONS[@]}"; do
            log_info "Installing extension: $ext"
            code --install-extension "$ext" --force >/dev/null 2>&1 || log_warning "Could not install $ext"
        done
        log_success "VS Code extensions installed"
    else
        log_warning "VS Code CLI not available for extensions"
    fi
else
    log_warning "VS Code not installed, skipping extensions"
fi

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