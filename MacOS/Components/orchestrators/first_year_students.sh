#!/bin/bash

_prefix="PYS:"

# checks for environmental variables for remote and branch
if [ -z "$REMOTE_PS" ]; then
  REMOTE_PS="dtudk/pythonsupport-scripts"
fi
if [ -z "$BRANCH_PS" ]; then
  BRANCH_PS="main"
fi

export REMOTE_PS
export BRANCH_PS

url_ps="https://raw.githubusercontent.com/$REMOTE_PS/$BRANCH_PS/MacOS/Components"

# Source the Piwik utility for analytics tracking
source_piwik_utility() {
    # Try to source the piwik utility - if it fails, define a fallback
    local piwik_script
    if piwik_script=$(curl -fsSL "$url_ps/Shared/piwik_utility.sh" 2>/dev/null) && [ -n "$piwik_script" ]; then
        eval "$piwik_script"
        echo "$_prefix Piwik analytics initialized"
    else
        echo "$_prefix Piwik utility not available, using fallback"
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

echo "$_prefix URL used for fetching scripts $url_ps"

echo "$_prefix First year students orchestrator started"

# install python using component
piwik_log 'python_component_install' /bin/bash -c "$(curl -fsSL $url_ps/Python/install.sh)"
_python_ret=$?

# install vscode using component
piwik_log 'vscode_component_install' /bin/bash -c "$(curl -fsSL $url_ps/VSC/install.sh)"
_vsc_ret=$?

# run first year python setup (install specific version and packages)
if [ $_python_ret -eq 0 ]; then
  echo "$_prefix Running first year Python environment setup..."
  piwik_log 'python_first_year_setup' /bin/bash -c "$(curl -fsSL $url_ps/Python/first_year_setup.sh)"
  _first_year_ret=$?
else
  _first_year_ret=0  # Skip if Python installation failed
fi

# install vscode extensions
if [ $_vsc_ret -eq 0 ]; then
  echo "$_prefix Installing VSCode extensions for Python development..."
  piwik_log 'vscode_extensions_install' /bin/bash -c "$(curl -fsSL $url_ps/VSC/install_extensions.sh)"
  _extensions_ret=$?
else
  _extensions_ret=0  # Skip if VSCode installation failed
fi

exit_message() {
  echo ""
  echo "Something went wrong in one of the installation runs."
  echo "Please see further up in the output for an error message..."
  echo ""
}

if [ $_python_ret -ne 0 ]; then
  exit_message
  exit $_python_ret
elif [ $_vsc_ret -ne 0 ]; then
  exit_message
  exit $_vsc_ret
elif [ $_first_year_ret -ne 0 ]; then
  exit_message
  exit $_first_year_ret
elif [ $_extensions_ret -ne 0 ]; then
  echo ""
  echo "VSCode extensions installation failed, but core installation succeeded."
  echo "You can install extensions manually later."
  echo ""
fi

# Track overall success/failure
if [ $_python_ret -eq 0 ] && [ $_vsc_ret -eq 0 ] && [ $_first_year_ret -eq 0 ] && [ $_extensions_ret -eq 0 ]; then
    piwik_log 'orchestrator_success' echo "All components installed successfully"
else
    piwik_log 'orchestrator_partial_failure' echo "Some components failed to install"
fi

echo ""
echo ""
echo "Script has finished. You may now close the terminal..."