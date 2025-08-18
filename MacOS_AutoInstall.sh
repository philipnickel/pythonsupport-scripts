#!/bin/bash
# @doc
# @name: MacOS Auto Installer
# @description: Main installation script for Python Support on macOS - installs Python and VSCode
# @category: Orchestrator
# @usage: bash MacOS_AutoInstall.sh
# @requirements: macOS system with admin privileges, internet connection
# @notes: Uses shared utilities for consistent error handling and logging
# @/doc

# Load shared utilities
source <(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Shared/load_utils.sh")

log_info "MacOS Auto Installer started"

# install python
log_info "Installing Python..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Python/Install.sh)"
_python_ret=$?

# install vscode
log_info "Installing VSCode..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/VSC/Install.sh)"
_vsc_ret=$?

# Check results and provide appropriate feedback
if [ $_python_ret -ne 0 ]; then
  log_error "Python installation failed"
  exit_message
elif [ $_vsc_ret -ne 0 ]; then
  log_error "VSCode installation failed"
  exit_message
else
  log_success "All installations completed successfully!"
fi

log_info "Script has finished. You may now close the terminal..."
