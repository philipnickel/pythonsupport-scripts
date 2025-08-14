#!/bin/bash

_prefix="PYS:"

# checks for environmental variables for remote and branch 
if [ -z "$REMOTE_PS" ]; then
  REMOTE_PS="dtudk/pythonsupport-scripts"
fi
if [ -z "$BRANCH_PS" ]; then
  BRANCH_PS="main"
fi
if [ -z "$PYTHON_VERSION_PS" ]; then
  PYTHON_VERSION_PS="3.11"
fi

export REMOTE_PS
export BRANCH_PS

_py_version=$PYTHON_VERSION_PS
url_ps="https://raw.githubusercontent.com/$REMOTE_PS/$BRANCH_PS/MacOS"

echo "$_prefix First year Python setup"

# Check if conda is installed, if not install Python first
if ! conda --version > /dev/null; then
  echo "$_prefix Conda not found. Installing Python with Miniconda first..."
  /bin/bash -c "$(curl -fsSL $url_ps/Components/Python/install.sh)"
  
  # Source the shell profile to get conda in PATH
  [ -e ~/.bashrc ] && source ~/.bashrc
  hash -r
fi

# Error function 
# Print error message, contact information and exits script
exit_message () {
  echo ""
  echo "Oh no! Something went wrong"
  echo ""
  echo "Please visit the following web page:"
  echo ""
  echo "   https://pythonsupport.dtu.dk/install/macos/automated-error.html"
  echo ""
  echo "or contact the Python Support Team:"
  echo ""
  echo "   pythonsupport@dtu.dk"
  echo ""
  echo "Or visit us during our office hours"
  open https://pythonsupport.dtu.dk/install/macos/automated-error.html
  exit 1
}

echo "$_prefix Ensuring Python version ${_py_version}..."
# Doing local strict channel-priority
conda install --strict-channel-priority python=${_py_version} -y
retval=$?
# If it fails, try to use the flexible way, but manually downgrade libmamba to conda-forge
if [ $retval -ne 0 ]; then
  echo "$_prefix Trying manual downgrading..."
  conda install python=${_py_version} conda-forge::libmamba conda-forge::libmambapy -y
  retval=$?
fi
[ $retval -ne 0 ] && exit_message
clear -x

echo "$_prefix Installing packages..."
conda install dtumathtools pandas scipy statsmodels uncertainties -y
[ $? -ne 0 ] && exit_message
clear -x

echo ""
echo "$_prefix Installed conda and related packages for 1st year at DTU!"