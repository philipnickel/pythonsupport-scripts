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

echo "$_prefix URL used for fetching scripts $url_ps"

# install python using component
/bin/bash -c "$(curl -fsSL $url_ps/Python/install.sh)"
_python_ret=$?

# install vscode using component
/bin/bash -c "$(curl -fsSL $url_ps/VSC/install.sh)"
_vsc_ret=$?

# run first year python setup (install specific version and packages)
if [ $_python_ret -eq 0 ]; then
  echo "$_prefix Running first year Python environment setup..."
  /bin/bash -c "$(curl -fsSL $url_ps/Python/first_year_setup.sh)"
  _first_year_ret=$?
else
  _first_year_ret=0  # Skip if Python installation failed
fi

# install vscode extensions
if [ $_vsc_ret -eq 0 ]; then
  echo "$_prefix Installing VSCode extensions for Python development..."
  /bin/bash -c "$(curl -fsSL $url_ps/VSC/install_extensions.sh)"
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

echo ""
echo ""
echo "Script has finished. You may now close the terminal..."