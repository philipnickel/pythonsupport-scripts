#!/bin/bash
# @doc
# @name: Dependency Management Utilities
# @description: Functions for checking and installing system dependencies like Homebrew and conda
# @category: Utilities
# @usage: source dependencies.sh
# @requirements: bash shell environment, internet connection
# @notes: Provides automated dependency installation and verification functions
# @/doc

# Function to ensure conda environment is available (replaces ensure_homebrew)
ensure_conda_available() {
    # Source shell profiles to make conda available
    [ -e ~/.bashrc ] && source ~/.bashrc 2>/dev/null || true
    [ -e ~/.bash_profile ] && source ~/.bash_profile 2>/dev/null || true  
    [ -e ~/.zshrc ] && source ~/.zshrc 2>/dev/null || true
    
    # Add miniforge to PATH if it exists
    if [ -d "$HOME/miniforge3/bin" ]; then
        export PATH="$HOME/miniforge3/bin:$PATH"
    fi
    
    # Update PATH hash
    hash -r
    
    if command -v conda >/dev/null 2>&1; then
        log_info "Conda is available"
        return 0
    else
        log_info "Conda not found in PATH"
        return 1
    fi
}

# Function to setup conda environment
ensure_conda_env() {
    if command -v conda >/dev/null 2>&1; then
        log_info "Setting up conda environment..."
        eval "$(conda shell.bash hook)" 2>/dev/null || true
        conda activate base 2>/dev/null || true
        log_success "Conda environment configured"
    else
        log_info "Conda not available - some functionality may be limited"
    fi
}

# Function to install conda packages
install_conda_package() {
    local package="$1"
    
    ensure_conda_available
    
    if ! conda list "$package" >/dev/null 2>&1; then
        log_info "Installing $package via conda..."
        conda install "$package" -y
        check_exit_code "Failed to install $package"
        log_success "$package installed successfully"
    else
        log_info "$package is already installed"
    fi
}

# Function to check if a package is available in conda
check_conda_package() {
    local package="$1"
    conda search "$package" >/dev/null 2>&1
}

# Function to update conda
update_conda() {
    ensure_conda_available
    log_info "Updating conda..."
    conda update conda -y
    check_exit_code "Failed to update conda"
    log_success "Conda updated successfully"
}

# Function to verify system dependencies
verify_dependencies() {
    local dependencies=("$@")
    local missing=()
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        exit_message
    fi
    
    log_success "All dependencies verified"
}