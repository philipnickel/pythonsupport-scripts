#!/bin/bash
# @doc
# @name: First Year Students Setup
# @description: Complete installation orchestrator for DTU first year students - installs Homebrew, Python, VSCode, and LaTeX
# @category: Orchestrator
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/orchestrators/first_year_students.sh)"
# @requirements: macOS system with admin privileges, internet connection
# @notes: Uses master utility system for consistent error handling, logging, and analytics tracking
# @/doc

# Load master utilities (includes Piwik analytics)
eval "$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Shared/master_utils.sh")"

log_info "First year students orchestrator started"

# install python using component
log_info "Installing Python..."
piwik_log 'python_component_install' env PYTHON_VERSION_PS="${PYTHON_VERSION_PS:-3.11}" REMOTE_PS="${REMOTE_PS:-dtudk/pythonsupport-scripts}" BRANCH_PS="${BRANCH_PS:-main}" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Python/install.sh)"
_python_ret=$?

# install vscode using component
log_info "Installing VSCode..."
piwik_log 'vscode_component_install' /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/VSC/install.sh)"
_vsc_ret=$?

# run first year python setup (install specific version and packages)
if [ $_python_ret -eq 0 ]; then
  log_info "Running first year Python environment setup..."
  piwik_log 'python_first_year_setup' env PYTHON_VERSION_PS="${PYTHON_VERSION_PS:-3.11}" REMOTE_PS="${REMOTE_PS:-dtudk/pythonsupport-scripts}" BRANCH_PS="${BRANCH_PS:-main}" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Python/first_year_setup.sh)"
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
if [ $_python_ret -eq 0 ] && [ $_vsc_ret -eq 0 ] && [ $_first_year_ret -eq 0 ] && [ $_extensions_ret -eq 0 ]; then
    piwik_log 'orchestrator_success' echo "All components installed successfully"
else
    piwik_log 'orchestrator_partial_failure' echo "Some components failed to install"
fi

log_info "Script has finished. You may now close the terminal..."

# Final step: run diagnostics report to validate installation and capture environment details
log_info "Launching final diagnostics report (an HTML report will open)..."
piwik_log 'diagnostics_final_report' /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${DIAG_REMOTE_PS:-philipnickel/pythonsupport-scripts}/${DIAG_BRANCH_PS:-main}/MacOS/Components/Diagnostics/generate_report.sh)"