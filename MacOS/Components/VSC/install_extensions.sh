#!/bin/bash
# @doc
# @name: VSCode Extensions Installation
# @description: Installs essential VSCode extensions for Python development
# @category: IDE
# @usage: bash install_extensions.sh
# @requirements: VSCode installed on system
# @notes: Installs Python extension pack and other development tools
# @/doc

# Load master utilities
eval "$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Shared/master_utils.sh")"

log_info "Installing Visual Studio Code extensions"
log_info "This will install Python, Jupyter, and PDF extensions..."

# Check if VS Code is installed, if not install it first
if ! command -v code > /dev/null; then
  log_info "Visual Studio Code is not installed. Installing VS Code first..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/VSC/install.sh)"
  
  # update binary locations 
  hash -r
fi



# Test if code is installed correctly
if ! code --version > /dev/null; then
    log_error "Visual Studio Code is not available. Please install it first."
    exit_message
fi

log_info "Installing extensions for Visual Studio Code..."

# install python extension
log_info "Installing Python extension..."
code --install-extension ms-python.python
check_exit_code "Failed to install Python extension"

# jupyter extension
log_info "Installing Jupyter extension..."
code --install-extension ms-toolsai.jupyter
check_exit_code "Failed to install Jupyter extension"

# pdf extension (for viewing pdfs inside vs code)
log_info "Installing PDF extension..."
code --install-extension tomoki1207.pdf
check_exit_code "Failed to install PDF extension"

log_success "Installed Visual Studio Code extensions successfully!"