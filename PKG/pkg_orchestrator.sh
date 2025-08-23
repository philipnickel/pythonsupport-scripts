#!/bin/bash
# PKG Self-Contained Orchestrator
# Uses bundled scripts instead of downloading from GitHub

set -euo pipefail

# Configuration for self-contained PKG
readonly ORCHESTRATOR_NAME="DTU First Year Setup"
readonly BUNDLE_DIR="/usr/local/share/dtu-python-env/Components"

# Set install method for analytics
export PIS_INSTALL_METHOD="${PIS_INSTALL_METHOD:-PKG}"
export PYTHON_VERSION_PS="${PYTHON_VERSION_PS:-3.11}"

# Detect CI environment and set conda ToS auto-acceptance
readonly IS_CI="${GITHUB_CI:-false}"
if [[ "$IS_CI" == "true" ]]; then
    export CONDA_PLUGINS_AUTO_ACCEPT_TOS=yes
    export CI=true
fi

# Load bundled utilities
if [[ -f "$BUNDLE_DIR/Shared/minimal_utils.sh" ]]; then
    source "$BUNDLE_DIR/Shared/minimal_utils.sh"
    # Check if required functions exist, if not use fallbacks
    if ! declare -f echo_success >/dev/null 2>&1; then
        echo_success() { echo "✅ $1"; }
        echo_error() { echo "❌ $1"; }
        echo_info() { echo "ℹ️ $1"; }
    fi
else
    # Fallback minimal functions if utils not available
    echo_success() { echo "✅ $1"; }
    echo_error() { echo "❌ $1"; }
    echo_info() { echo "ℹ️ $1"; }
fi

# Component installation functions
install_homebrew_if_missing() {
    if ! command -v brew >/dev/null 2>&1; then
        echo_info "Checking for existing Homebrew installation..."
        
        # Check if Homebrew is available in standard locations
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            echo_info "Homebrew found at /opt/homebrew/bin/brew"
            export PATH="/opt/homebrew/bin:$PATH"
            return 0
        elif [[ -f "/usr/local/bin/brew" ]]; then
            echo_info "Homebrew found at /usr/local/bin/brew"
            export PATH="/usr/local/bin:$PATH"
            return 0
        fi
        
        # In CI environment, we should have Homebrew available
        if [[ "$IS_CI" == "true" ]]; then
            echo_info "Running in CI environment, Homebrew should be available"
            # Try to find Homebrew in PATH
            if command -v brew >/dev/null 2>&1; then
                echo_info "Homebrew found in PATH"
                return 0
            else
                echo_error "Homebrew not found in CI environment"
                return 1
            fi
        fi
        
        # For local installation, we can't install Homebrew as root
        echo_error "Homebrew not found and cannot install as root"
        echo_error "Please install Homebrew manually: https://brew.sh"
        return 1
    fi
}

install_miniforge() {
    echo_info "Checking Python/Miniforge installation..."
    
    # Check if conda is already available and working
    if command -v conda >/dev/null 2>&1; then
        local version=$(conda --version 2>/dev/null || echo "unknown version")
        echo_success "Python/Miniforge already available ($version)"
        
        # Verify channel configuration (Miniforge should already be configured for conda-forge)
        echo_info "Verifying conda channel configuration..."
        conda config --show channels
        
        return 0
    fi
    
    # Only try to install Miniforge if conda is not available
    echo_info "Conda not found, attempting to install Miniforge..."
    
    # Download and install Miniforge
    local miniforge_installer="/tmp/Miniforge3.sh"
    local arch=$(uname -m)
    local os=$(uname)
    
    # Determine the correct installer URL
    if [[ "$os" == "Darwin" ]]; then
        if [[ "$arch" == "arm64" ]]; then
            local installer_url="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh"
        else
            local installer_url="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh"
        fi
    else
        local installer_url="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
    fi
    
    echo_info "Downloading Miniforge installer from: $installer_url"
    
    # Download the installer
    if curl -L -o "$miniforge_installer" "$installer_url"; then
        echo_info "Miniforge installer downloaded successfully"
        
        # Make it executable and install
        chmod +x "$miniforge_installer"
        
        # Install Miniforge in batch mode (non-interactive)
        echo_info "Installing Miniforge..."
        if bash "$miniforge_installer" -b -p "$HOME/miniforge3"; then
            # Initialize conda
            local conda_base="$HOME/miniforge3"
            
            if [[ -f "$conda_base/bin/conda" ]]; then
                # Initialize conda properly for all shells
                echo_info "Initializing conda for all shells..."
                eval "$($conda_base/bin/conda shell.bash hook)"
                conda init bash zsh fish >/dev/null 2>&1 || true
                
                # Set up conda to take precedence in shell profiles
                echo_info "Setting up conda to take precedence in shell profiles..."
                for shell in bash zsh; do
                    local profile_file="$HOME/.${shell}rc"
                    [[ "$shell" == "bash" ]] && profile_file="$HOME/.bash_profile"
                    
                    # Add conda initialization to shell profile if not already present
                    if [[ -f "$profile_file" ]] && ! grep -q "conda initialize" "$profile_file"; then
                        echo "" >> "$profile_file"
                        echo "# >>> conda initialize >>>" >> "$profile_file"
                        echo "# !! Contents within this block are managed by 'conda init' !!" >> "$profile_file"
                        echo "__conda_setup=\"\$('$conda_base/bin/conda' 'shell.$shell' 'hook' 2> /dev/null)\"" >> "$profile_file"
                        echo "if [ \$? -eq 0 ]; then" >> "$profile_file"
                        echo "    eval \"\$__conda_setup\"" >> "$profile_file"
                        echo "else" >> "$profile_file"
                        echo "    if [ -f \"$conda_base/etc/profile.d/conda.sh\" ]; then" >> "$profile_file"
                        echo "        . \"$conda_base/etc/profile.d/conda.sh\"" >> "$profile_file"
                        echo "    else" >> "$profile_file"
                        echo "        export PATH=\"$conda_base/bin:\$PATH\"" >> "$profile_file"
                        echo "    fi" >> "$profile_file"
                        echo "fi" >> "$profile_file"
                        echo "unset __conda_setup" >> "$profile_file"
                        echo "# <<< conda initialize <<<" >> "$profile_file"
                    fi
                done
                
                # Also add conda to PATH for current session
                echo_info "Adding conda to PATH for current session..."
                export PATH="$conda_base/bin:$PATH"
                
                # Verify channel configuration
                echo_info "Verifying conda channel configuration..."
                conda config --show channels
                
                # Clean up installer
                rm -f "$miniforge_installer"
                
                echo_success "Python/Miniforge installed successfully"
                return 0
            else
                echo_error "Python/Miniforge installation completed but conda not accessible"
                rm -f "$miniforge_installer"
                return 1
            fi
        else
            echo_error "Python/Miniforge installation failed"
            rm -f "$miniforge_installer"
            return 1
        fi
    else
        echo_error "Failed to download Miniforge installer"
        return 1
    fi
}

setup_python_environment() {
    echo_info "Setting up Python Environment..."
    
    # Activate conda
    eval "$(conda shell.bash hook)" 2>/dev/null || true
    conda activate base 2>/dev/null || true
    
    # Check if correct Python version is installed
    if command -v python3 >/dev/null 2>&1; then
        local current_version
        current_version=$(python3 --version 2>/dev/null | cut -d' ' -f2)
        
        if [[ "$current_version" =~ ^3\.11 ]]; then
            # Check if required packages are installed
            local required_packages=("dtumathtools" "pandas" "scipy" "statsmodels" "uncertainties")
            local missing_packages=()
            
            for package in "${required_packages[@]}"; do
                if ! python3 -c "import $package" 2>/dev/null; then
                    missing_packages+=("$package")
                fi
            done
            
            if [[ ${#missing_packages[@]} -eq 0 ]]; then
                echo_success "Python Environment already configured (Python $current_version with all packages)"
                return 0
            fi
        fi
    fi
    
    # Install Python version (Miniforge comes with Python, but we can specify version if needed)
    echo_info "Installing Python 3.11..."
    if conda install "python=3.11" -y; then
        echo_info "Python 3.11 installed"
    else
        echo_error "Failed to install Python 3.11"
        return 1
    fi
    
    # Install required packages
    local package_list="dtumathtools pandas scipy statsmodels uncertainties"
    echo_info "Installing required packages..."
    if conda install $package_list -y; then
        echo_success "Python Environment configured successfully"
        return 0
    else
        echo_error "Failed to install required packages"
        return 1
    fi
}

install_vscode() {
    echo_info "Installing VS Code..."
    
    # Check if already installed
    if command -v code >/dev/null 2>&1; then
        local version=$(code --version 2>/dev/null | head -1 || echo "unknown version")
        echo_success "VS Code already installed ($version)"
        return 0
    fi
    
    # Ensure Homebrew is available
    install_homebrew_if_missing
    
    # Install VS Code
    if brew install --cask visual-studio-code; then
        # Verify installation
        if command -v code >/dev/null 2>&1; then
            echo_success "VS Code installed successfully"
            return 0
        else
            echo_error "VS Code installation completed but 'code' command not available"
            return 1
        fi
    else
        echo_error "VS Code installation failed"
        return 1
    fi
}

echo "=== $ORCHESTRATOR_NAME ==="
echo "Installing development environment using bundled components..."
echo "Bundle directory: $BUNDLE_DIR"
echo "CI Environment: $IS_CI"
echo ""

# Debug information
echo "DEBUG: Current user: $(id)"
echo "DEBUG: Current directory: $(pwd)"
echo "DEBUG: Environment variables:"
env | grep -E "(PIS_|PYTHON_)" || echo "No PIS_/PYTHON_ variables found"

# Check if bundle directory exists
echo "DEBUG: Checking bundle directory..."
ls -la /usr/local/share/ || echo "ERROR: /usr/local/share not found"
ls -la "$BUNDLE_DIR" || echo "ERROR: Bundle directory not accessible"

if [[ ! -d "$BUNDLE_DIR" ]]; then
    echo_error "Bundle directory not found: $BUNDLE_DIR"
    echo "This PKG may be corrupted or incomplete."
    exit 1
fi

# List available components
echo "DEBUG: Available components:"
find "$BUNDLE_DIR" -name "*.sh" | head -10

# Install components
success_count=0
total_components=0

# Python/Miniconda
echo "----------------------------------------"
((total_components++))
    if install_miniforge; then
    ((success_count++))
fi

# Python Environment Setup
echo "----------------------------------------"
((total_components++))
if setup_python_environment; then
    ((success_count++))
fi

# VS Code
echo "----------------------------------------"
((total_components++))
if install_vscode; then
    ((success_count++))
fi

echo "----------------------------------------"
echo "=== Installation Summary ==="
echo "Successfully installed: $success_count/$total_components components"

if [[ $success_count -eq $total_components ]]; then
    echo_success "All components installed successfully!"
    echo ""
    echo "Your DTU Python development environment is ready!"
    echo ""
    echo "Next steps:"
    echo "1. Open a new terminal window"
    echo "2. Run: conda --version"
    echo "3. Run: python --version"
    echo "4. Run: code --version"
    exit 0
else
    echo_error "Some components failed to install"
    echo "Please check the error messages above"
    exit 1
fi