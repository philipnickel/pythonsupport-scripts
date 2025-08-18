#!/bin/bash
# @doc
# @name: First Year Students Setup
# @description: Complete installation orchestrator for DTU first year students - installs Homebrew, Python, VSCode, and LaTeX
# @category: Orchestrator
# @usage: bash first_year_students.sh
# @requirements: macOS system with admin privileges, internet connection
# @notes: Uses shared utilities for consistent error handling, logging, and analytics tracking
# @/doc

# Load shared utilities
source <(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Shared/load_utils.sh")

# Source the Piwik utility for analytics tracking
source_piwik_utility() {
    local piwik_url="https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Shared/piwik_utility.sh"
    
    if piwik_script=$(curl -fsSL "$piwik_url" 2>/dev/null) && [ -n "$piwik_script" ]; then
        eval "$piwik_script"
        log_success "Piwik analytics initialized"
    else
        log_warning "Piwik utility not available, using fallback"
        # Fallback: define piwik_log as a pass-through function
        piwik_log() {
            shift  # Remove the event name (first argument)
            "$@"   # Execute the actual command
            return $?
        }
    fi
}

# Initialize Piwik utility
source_piwik_utility

log_info "First year students orchestrator started"

# install python using component
log_info "Installing Python..."
piwik_log 'python_component_install' /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Python/install.sh)"
_python_ret=$?

# install vscode using component
log_info "Installing VSCode..."
piwik_log 'vscode_component_install' /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/VSC/install.sh)"
_vsc_ret=$?

# run first year python setup (install specific version and packages)
if [ $_python_ret -eq 0 ]; then
  log_info "Running first year Python environment setup..."
  piwik_log 'python_first_year_setup' /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Python/first_year_setup.sh)"
  _first_year_ret=$?
else
  _first_year_ret=0  # Skip if Python installation failed
fi

# install vscode extensions
if [ $_vsc_ret -eq 0 ]; then
  log_info "Installing VSCode extensions for Python development..."
  piwik_log 'vscode_extensions_install' /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/VSC/install_extensions.sh)"
  _extensions_ret=$?
else
  _extensions_ret=0  # Skip if VSCode installation failed
fi

# Check results and provide appropriate feedback
if [ $_python_ret -ne 0 ]; then
  log_error "Python installation failed"
  exit_message
elif [ $_vsc_ret -ne 0 ]; then
  log_error "VSCode installation failed"
  exit_message
elif [ $_first_year_ret -ne 0 ]; then
  log_error "First year Python setup failed"
  exit_message
elif [ $_extensions_ret -ne 0 ]; then
  log_warning "VSCode extensions installation failed, but core installation succeeded"
  log_info "You can install extensions manually later"
else
  log_success "All installations completed successfully!"
fi

# Track overall success/failure