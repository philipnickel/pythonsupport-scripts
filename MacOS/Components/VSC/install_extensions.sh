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

url_ps="https://raw.githubusercontent.com/$REMOTE_PS/$BRANCH_PS/MacOS"

echo "$_prefix Installing Visual Studio Code extensions"
echo "$_prefix This will install Python, Jupyter, and PDF extensions..."

# Check if VS Code is installed, if not install it first
if ! command -v code > /dev/null; then
  echo "$_prefix Visual Studio Code is not installed. Installing VS Code first..."
  /bin/bash -c "$(curl -fsSL $url_ps/Components/VSC/install.sh)"
  
  # update binary locations 
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

# Test if code is installed correctly
if ! code --version > /dev/null; then
    echo "$_prefix Visual Studio Code is not available. Please install it first."
    exit_message
fi

echo "$_prefix Installing extensions for Visual Studio Code..."

# install python extension
echo "$_prefix Installing Python extension..."
code --install-extension ms-python.python
[ $? -ne 0 ] && exit_message

# jupyter extension
echo "$_prefix Installing Jupyter extension..."
code --install-extension ms-toolsai.jupyter
[ $? -ne 0 ] && exit_message

# pdf extension (for viewing pdfs inside vs code)
echo "$_prefix Installing PDF extension..."
code --install-extension tomoki1207.pdf
[ $? -ne 0 ] && exit_message

echo ""
echo "$_prefix Installed Visual Studio Code extensions successfully!"