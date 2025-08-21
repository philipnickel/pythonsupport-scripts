#!/bin/bash
# @doc
# @name: Dependency Management Utilities
# @description: Functions for checking and installing system dependencies like Homebrew and conda
# @category: Utilities
# @usage: source dependencies.sh
# @requirements: bash shell environment, internet connection
# @notes: Provides automated dependency installation and verification functions
# @/doc

# Function to check and install Homebrew if needed
ensure_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        log_info "Homebrew is not installed. Installing Homebrew..."
        local url_ps=$(get_base_url)
        log_info "Installing from $url_ps/Components/Homebrew/install.sh"
        /bin/bash -c "$(curl -fsSL $url_ps/Components/Homebrew/install.sh)"

        # The above will install everything in a subshell.
        # So just to be sure we have it on the path
        [ -e ~/.bash_profile ] && source ~/.bash_profile
        [ -e ~/.zshrc ] && source ~/.zshrc

        # update binary locations 
        hash -r
        
        # Verify installation
        if ! command -v brew >/dev/null 2>&1; then
            log_error "Homebrew installation failed"
            exit_message
        fi
        
        log_success "Homebrew installed successfully"
    else
        log_info "Homebrew is already installed"
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

# Function to install Homebrew packages
install_brew_package() {
    local package="$1"
    local cask="$2"
    
    ensure_homebrew
    
    if [ "$cask" = "true" ]; then
        if ! brew list --cask "$package" >/dev/null 2>&1; then
            log_info "Installing $package via Homebrew cask..."
            export HOMEBREW_NO_AUTO_UPDATE=1
            brew install --cask "$package"
            check_exit_code "Failed to install $package"
            log_success "$package installed successfully"
        else
            log_info "$package is already installed"
        fi
    else
        if ! brew list "$package" >/dev/null 2>&1; then
            log_info "Installing $package via Homebrew..."
            export HOMEBREW_NO_AUTO_UPDATE=1
            brew install "$package"
            check_exit_code "Failed to install $package"
            log_success "$package installed successfully"
        else
            log_info "$package is already installed"
        fi
    fi
}

# Function to check if a package is available in Homebrew
check_brew_package() {
    local package="$1"
    brew search "$package" >/dev/null 2>&1
}

# Function to update Homebrew
update_homebrew() {
    ensure_homebrew
    log_info "Updating Homebrew..."
    brew update
    check_exit_code "Failed to update Homebrew"
    log_success "Homebrew updated successfully"
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