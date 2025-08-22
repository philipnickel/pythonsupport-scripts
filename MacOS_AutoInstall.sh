#!/bin/bash
# Legacy compatibility wrapper for MacOS installation
# This script maintains compatibility with the old installation workflow

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

# install python with first year packages using new component structure
/bin/bash -c "$(curl -fsSL $url_ps/Python/first_year_setup.sh)"
_python_ret=$?

# install vscode using new component structure
/bin/bash -c "$(curl -fsSL $url_ps/VSC/install.sh)"
_vsc_ret=$?

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
fi

echo ""
echo ""
echo "Script has finished. You may now close the terminal..."