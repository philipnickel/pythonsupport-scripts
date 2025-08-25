#!/bin/bash
# @doc
# @name: Pre-Installation Check Script
# @description: Checks for existing installations and system requirements before running the main installer
# @category: Core
# @usage: ./pre_install.sh
# @requirements: macOS system
# @notes: Should be run before any installation process to assess system state
# @/doc

# Set strict error handling
set -e

# Load utilities with new filename to break CDN cache
if ! eval "$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared/common.sh")"; then
    echo "ERROR: Failed to load utilities from remote repository"
    exit 1
fi

log_info "DTU Python Support - Pre-Installation Check"
log_info "=============================================="

# Variables for tracking found installations
PYTHON_FOUND=false
PYTHON_VERSION=""
PYTHON_PATH=""
VSCODE_FOUND=false
VSCODE_VERSION=""
CONDA_FOUND=false
CONDA_TYPE=""
CONDA_VERSION=""
PYTHON_PACKAGES_FOUND=false
VSCODE_EXTENSIONS_FOUND=false
WARNINGS=()
ERRORS=()

# Check system requirements
check_system_requirements() {
    log_info "Checking system requirements..."
    
    # Check macOS version
    if ! sw_vers >/dev/null 2>&1; then
        ERRORS+=("This script requires macOS")
        return 1
    fi
    
    local macos_version=$(sw_vers -productVersion)
    local major_version=$(echo "$macos_version" | cut -d. -f1)
    local minor_version=$(echo "$macos_version" | cut -d. -f2)
    
    log_info "macOS version: $macos_version"
    
    # Check for minimum macOS version (10.14 Mojave)
    if [ "$major_version" -lt 10 ] || ([ "$major_version" -eq 10 ] && [ "$minor_version" -lt 14 ]); then
        ERRORS+=("macOS 10.14 (Mojave) or later is required")
    fi
    
    # Check architecture
    local arch=$(uname -m)
    log_info "Architecture: $arch"
    
    # Check available disk space (need at least 2GB free)
    local free_space_kb=$(df -k / | tail -1 | awk '{print $4}')
    local free_space_gb=$((free_space_kb / 1024 / 1024))
    
    log_info "Available disk space: ${free_space_gb}GB"
    
    if [ "$free_space_gb" -lt 2 ]; then
        WARNINGS+=("Low disk space (${free_space_gb}GB available). At least 2GB recommended.")
    fi
    
    # Check internet connectivity
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        WARNINGS+=("Internet connectivity check failed. Installation may not work properly.")
    fi
}

# Check for existing Python installations
check_python_installations() {
    log_info "Checking for existing Python installations..."
    
    # Check system Python 3
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_FOUND=true
        PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
        PYTHON_PATH=$(which python3)
        
        log_info "Found Python 3: $PYTHON_VERSION at $PYTHON_PATH"
        
        # Check if it's the target version (3.11.x)
        if echo "$PYTHON_VERSION" | grep -q "^3\.11\."; then
            log_success "Python 3.11 already installed"
        else
            WARNINGS+=("Python $PYTHON_VERSION found, but DTU requires Python 3.11.x")
        fi
        
        # Check for required packages
        check_python_packages
    else
        log_info "No Python 3 installation found"
    fi
    
    # Check for conda/miniconda/anaconda
    check_conda_installations
}

# Check for conda installations
check_conda_installations() {
    log_info "Checking for conda environments..."
    
    # Check various conda installation locations
    local conda_paths=(
        "$HOME/miniconda3/bin/conda"
        "$HOME/anaconda3/bin/conda"
        "$HOME/miniforge3/bin/conda"
        "/opt/miniconda3/bin/conda"
        "/opt/anaconda3/bin/conda"
        "/opt/miniforge3/bin/conda"
        "/usr/local/miniconda3/bin/conda"
        "/usr/local/anaconda3/bin/conda"
    )
    
    for conda_path in "${conda_paths[@]}"; do
        if [ -x "$conda_path" ]; then
            CONDA_FOUND=true
            CONDA_VERSION=$("$conda_path" --version 2>/dev/null | cut -d' ' -f2)
            
            # Determine conda type
            if echo "$conda_path" | grep -q "miniconda"; then
                CONDA_TYPE="Miniconda"
            elif echo "$conda_path" | grep -q "anaconda"; then
                CONDA_TYPE="Anaconda"
            elif echo "$conda_path" | grep -q "miniforge"; then
                CONDA_TYPE="Miniforge"
            else
                CONDA_TYPE="Conda"
            fi
            
            log_info "Found $CONDA_TYPE $CONDA_VERSION at $conda_path"
            break
        fi
    done
    
    # Also check if conda command is in PATH
    if command -v conda >/dev/null 2>&1 && [ "$CONDA_FOUND" = false ]; then
        CONDA_FOUND=true
        CONDA_VERSION=$(conda --version 2>/dev/null | cut -d' ' -f2)
        CONDA_TYPE="Conda (in PATH)"
        log_info "Found conda $CONDA_VERSION in PATH"
    fi
    
    if [ "$CONDA_FOUND" = false ]; then
        log_info "No conda installation found"
    fi
}

# Check for required Python packages
check_python_packages() {
    if [ "$PYTHON_FOUND" = true ]; then
        log_info "Checking for required Python packages..."
        
        local packages=("dtumathtools" "pandas" "scipy" "statsmodels" "uncertainties")
        local found_packages=()
        local missing_packages=()
        
        for package in "${packages[@]}"; do
            if python3 -c "import $package" 2>/dev/null; then
                found_packages+=("$package")
            else
                missing_packages+=("$package")
            fi
        done
        
        if [ ${#found_packages[@]} -gt 0 ]; then
            PYTHON_PACKAGES_FOUND=true
            log_info "Found packages: ${found_packages[*]}"
        fi
        
        if [ ${#missing_packages[@]} -gt 0 ]; then
            log_info "Missing packages: ${missing_packages[*]}"
        fi
        
        if [ ${#found_packages[@]} -eq ${#packages[@]} ]; then
            log_success "All required Python packages are installed"
        fi
    fi
}

# Check for Visual Studio Code
check_vscode_installation() {
    log_info "Checking for Visual Studio Code..."
    
    # Check common VS Code installation locations
    local vscode_paths=(
        "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
        "/usr/local/bin/code"
        "/opt/homebrew/bin/code"
    )
    
    for vscode_path in "${vscode_paths[@]}"; do
        if [ -x "$vscode_path" ]; then
            VSCODE_FOUND=true
            VSCODE_VERSION=$("$vscode_path" --version 2>/dev/null | head -1)
            log_info "Found VS Code $VSCODE_VERSION at $vscode_path"
            break
        fi
    done
    
    # Also check if code command is in PATH
    if command -v code >/dev/null 2>&1 && [ "$VSCODE_FOUND" = false ]; then
        VSCODE_FOUND=true
        VSCODE_VERSION=$(code --version 2>/dev/null | head -1)
        log_info "Found VS Code $VSCODE_VERSION in PATH"
    fi
    
    if [ "$VSCODE_FOUND" = false ]; then
        log_info "Visual Studio Code not found"
    else
        check_vscode_extensions
    fi
}

# Check for VS Code Python extension
check_vscode_extensions() {
    if [ "$VSCODE_FOUND" = true ]; then
        log_info "Checking for VS Code Python extension..."
        
        if code --list-extensions 2>/dev/null | grep -q "ms-python.python"; then
            VSCODE_EXTENSIONS_FOUND=true
            log_success "Python extension for VS Code is installed"
        else
            log_info "Python extension for VS Code not found"
        fi
    fi
}

# Generate summary report
generate_summary() {
    echo ""
    log_info "Pre-Installation Summary"
    log_info "========================"
    
    echo "System Requirements:"
    echo "  ✓ macOS system detected"
    echo "  ✓ Architecture: $(uname -m)"
    echo "  ✓ macOS version: $(sw_vers -productVersion)"
    
    echo ""
    echo "Current Installation Status:"
    
    if [ "$PYTHON_FOUND" = true ]; then
        echo "  Python 3: ✓ Found ($PYTHON_VERSION)"
        if [ "$PYTHON_PACKAGES_FOUND" = true ]; then
            echo "  Python packages: ✓ Some packages found"
        else
            echo "  Python packages: ✗ None found"
        fi
    else
        echo "  Python 3: ✗ Not found"
        echo "  Python packages: ✗ Not applicable"
    fi
    
    if [ "$CONDA_FOUND" = true ]; then
        echo "  Conda: ✓ Found ($CONDA_TYPE $CONDA_VERSION)"
    else
        echo "  Conda: ✗ Not found"
    fi
    
    if [ "$VSCODE_FOUND" = true ]; then
        echo "  VS Code: ✓ Found ($VSCODE_VERSION)"
        if [ "$VSCODE_EXTENSIONS_FOUND" = true ]; then
            echo "  Python extension: ✓ Found"
        else
            echo "  Python extension: ✗ Not found"
        fi
    else
        echo "  VS Code: ✗ Not found"
        echo "  Python extension: ✗ Not applicable"
    fi
    
    # Show warnings
    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo ""
        echo "Warnings:"
        for warning in "${WARNINGS[@]}"; do
            echo "  ⚠  $warning"
        done
    fi
    
    # Show errors
    if [ ${#ERRORS[@]} -gt 0 ]; then
        echo ""
        echo "Errors:"
        for error in "${ERRORS[@]}"; do
            echo "  ✗ $error"
        done
        echo ""
        log_error "System requirements not met. Installation cannot proceed."
        return 1
    fi
    
    echo ""
    if [ "$PYTHON_FOUND" = true ] && [ "$VSCODE_FOUND" = true ] && [ "$PYTHON_PACKAGES_FOUND" = true ] && [ "$VSCODE_EXTENSIONS_FOUND" = true ]; then
        log_success "Complete DTU first-year setup detected. Installation may not be necessary."
    elif [ "$PYTHON_FOUND" = true ] || [ "$VSCODE_FOUND" = true ] || [ "$CONDA_FOUND" = true ]; then
        log_info "Partial installation detected. Installation will update/complete the setup."
    else
        log_info "No existing installations found. Fresh installation will proceed."
    fi
    
    return 0
}

# Export findings for use by other scripts
export_findings() {
    # Create a summary file that other scripts can source
    cat > /tmp/dtu_pre_install_findings.env << EOF
# DTU Pre-Installation Findings
# Generated: $(date)

PYTHON_FOUND=$PYTHON_FOUND
PYTHON_VERSION="$PYTHON_VERSION"
PYTHON_PATH="$PYTHON_PATH"
VSCODE_FOUND=$VSCODE_FOUND
VSCODE_VERSION="$VSCODE_VERSION"
CONDA_FOUND=$CONDA_FOUND
CONDA_TYPE="$CONDA_TYPE"
CONDA_VERSION="$CONDA_VERSION"
PYTHON_PACKAGES_FOUND=$PYTHON_PACKAGES_FOUND
VSCODE_EXTENSIONS_FOUND=$VSCODE_EXTENSIONS_FOUND
EOF
    
    log_info "Pre-installation findings saved to /tmp/dtu_pre_install_findings.env"
}

# Main execution
main() {
    echo "DTU Python Support - Pre-Installation Check"
    echo "============================================="
    echo ""
    
    # Run all checks
    check_system_requirements || return 1
    check_python_installations
    check_vscode_installation
    
    # Generate summary and export findings
    if generate_summary; then
        export_findings
        echo ""
        log_success "Pre-installation check completed successfully"
        return 0
    else
        log_error "Pre-installation check failed"
        return 1
    fi
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi