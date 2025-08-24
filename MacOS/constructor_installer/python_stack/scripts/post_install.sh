#!/bin/bash
# Post-install script for DTU Python Stack
# Handles Python environment + VS Code + Extensions + Diagnostics

set -euo pipefail

# Logging functions
log_info() {
    echo "[INFO] $*"
}

log_success() {
    echo "[SUCCESS] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
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
conda config --set anaconda_anon_usage off
conda config --set auto_activate_base true

# Shell integration
conda init bash 2>/dev/null || true
conda init zsh 2>/dev/null || true

log_success "Python environment configured"

# =============================================================================
# Phase 2: VS Code Installation
# =============================================================================

log_info "Installing Visual Studio Code..."

# VS Code download URL (always get latest stable)
VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=darwin-universal"
VSCODE_ZIP="/tmp/vscode.zip"
VSCODE_APP="/Applications/Visual Studio Code.app"

# Check if VS Code is already installed
if [ -d "$VSCODE_APP" ]; then
    log_info "VS Code already installed, skipping download"
else
    log_info "Downloading VS Code from Microsoft..."
    if curl -fsSL -o "$VSCODE_ZIP" "$VSCODE_URL"; then
        log_success "VS Code downloaded"
        
        log_info "Installing VS Code to Applications..."
        unzip -q "$VSCODE_ZIP" -d /tmp/
        mv "/tmp/Visual Studio Code.app" "$VSCODE_APP"
        
        # Clean up
        rm -f "$VSCODE_ZIP"
        
        log_success "VS Code installed successfully"
    else
        log_error "Failed to download VS Code"
        log_warning "Continuing without VS Code - you can install it manually later"
    fi
fi

# =============================================================================
# Phase 3: VS Code CLI Tools Setup
# =============================================================================

log_info "Setting up VS Code CLI tools..."

# Add VS Code CLI to PATH by creating symlink
VSCODE_CLI="/usr/local/bin/code"
VSCODE_BINARY="$VSCODE_APP/Contents/Resources/app/bin/code"

if [ -f "$VSCODE_BINARY" ]; then
    # Create /usr/local/bin if it doesn't exist
    sudo mkdir -p /usr/local/bin
    
    # Remove existing symlink if present
    sudo rm -f "$VSCODE_CLI"
    
    # Create new symlink
    sudo ln -sf "$VSCODE_BINARY" "$VSCODE_CLI"
    
    log_success "VS Code CLI tools configured (code command available)"
else
    log_warning "VS Code binary not found, CLI tools not configured"
fi

# =============================================================================
# Phase 4: VS Code Extensions Installation
# =============================================================================

log_info "Installing VS Code Python extensions..."

if command -v code >/dev/null 2>&1; then
    # Essential Python extensions for DTU courses
    EXTENSIONS=(
        "ms-python.python"
        "ms-toolsai.jupyter"
        "ms-python.pylint"
        "ms-python.flake8"
        "ms-python.black-formatter"
    )
    
    for extension in "${EXTENSIONS[@]}"; do
        log_info "Installing extension: $extension"
        if code --install-extension "$extension" --force; then
            log_success "Installed: $extension"
        else
            log_warning "Failed to install: $extension"
        fi
    done
    
    log_success "VS Code extensions installation completed"
else
    log_warning "VS Code CLI not available, skipping extensions"
fi

# =============================================================================
# Phase 5: Diagnostics System
# =============================================================================

log_info "Running final diagnostics..."

# Determine project root and diagnostics script location
INSTALL_ROOT="$HOME/dtu-python-stack"
DIAGNOSTICS_SCRIPT=""

# Look for diagnostics script in common locations
POSSIBLE_LOCATIONS=(
    "$INSTALL_ROOT/generate_report.sh"
    "$HOME/.local/share/dtu-python-stack/generate_report.sh"
    "/tmp/dtu-diagnostics/generate_report.sh"
)

# Try to download diagnostics script if not found locally
GITHUB_DIAGNOSTICS_URL="https://raw.githubusercontent.com/philipnickel/PIS_ekstraRepo/main/MacOS/Components/Diagnostics/generate_report.sh"

for location in "${POSSIBLE_LOCATIONS[@]}"; do
    if [ -f "$location" ]; then
        DIAGNOSTICS_SCRIPT="$location"
        break
    fi
done

if [ -z "$DIAGNOSTICS_SCRIPT" ]; then
    log_info "Downloading diagnostics script..."
    DIAGNOSTICS_SCRIPT="/tmp/generate_report.sh"
    if curl -fsSL -o "$DIAGNOSTICS_SCRIPT" "$GITHUB_DIAGNOSTICS_URL"; then
        chmod +x "$DIAGNOSTICS_SCRIPT"
        log_success "Diagnostics script downloaded"
    else
        log_warning "Could not download diagnostics script"
        DIAGNOSTICS_SCRIPT=""
    fi
fi

if [ -n "$DIAGNOSTICS_SCRIPT" ] && [ -f "$DIAGNOSTICS_SCRIPT" ]; then
    log_info "Running installation diagnostics..."
    
    # Run diagnostics with appropriate environment
    export PATH="/usr/local/bin:$PATH"
    if bash "$DIAGNOSTICS_SCRIPT"; then
        log_success "Diagnostics completed successfully"
    else
        log_warning "Diagnostics completed with warnings"
    fi
else
    log_warning "Diagnostics script not available, skipping final verification"
fi

# =============================================================================
# Installation Complete
# =============================================================================

log_success " DTU Python Development Environment installation completed!"
log_info ""
log_info "=== Installation Summary ==="
log_info "✓ Python 3.11 with scientific packages (pandas, scipy, statsmodels, uncertainties, dtumathtools)"
log_info "✓ Conda environment activated and shell integration configured"

if [ -d "$VSCODE_APP" ]; then
    log_info "✓ Visual Studio Code installed with Python extensions"
    if command -v code >/dev/null 2>&1; then
        log_info "✓ VS Code CLI tools configured (code command available)"
    fi
fi

log_info ""
log_info "=== Next Steps ==="
log_info "1. Restart your terminal or run: source ~/.bash_profile (or ~/.zshrc)"
log_info "2. Test Python: python3 -c \"import pandas, dtumathtools; print('Success!')\""
log_info "3. Test VS Code: code --version"
log_info "4. Refer to your course materials for usage guidance"
log_info ""
log_info "Need help? Visit: https://pythonsupport.dtu.dk"
log_info ""

exit 0