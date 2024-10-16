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

# set URL
url_ps="https://raw.githubusercontent.com/$REMOTE_PS/$BRANCH_PS/MacOS"



# Check for homebrew
# if not installed call homebrew installation script
if ! command -v brew > /dev/null; then
  echo "$_prefix Homebrew is not installed. Installing Homebrew..."
  echo "$_prefix Installing from $url_ps/Homebrew/Install.sh"
  /bin/bash -c "$(curl -fsSL $url_ps/Homebrew/Install.sh)"

  # The above will install everything in a subshell.
  # So just to be sure we have it on the path
  [ -e ~/.bash_profile ] && source ~/.bash_profile

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




# check if vs code is installed
# using multipleVersionsMac to check 
echo "$_prefix Installing Visual Studio Code if not already installed..."
# if output is empty, then install vs code
vspath=$(/bin/bash -c "$(curl -fsSL $url_ps/VSC/multipleVersions.sh)")
[ $? -ne 0 ] && exit_message

if [ -n "$vspath" ]  ; then
    echo "$_prefix Visual Studio Code is already installed"
else
    echo "$_prefix Installing Visual Studio Code"
    brew install --cask visual-studio-code
    [ $? -ne 0 ] && exit_message
fi

hash -r 
clear -x


echo "$_prefix Installing extensions for Visual Studio Code"
eval "$(brew shellenv)"

# Test if code is installed correctly
if code --version > /dev/null; then
    echo "$_prefix Visual Studio Code installed successfully"
else
    echo "$_prefix Visual Studio Code installation failed. Exiting"
    exit_message
fi
clear -x

echo "$_prefix Installing extensions for Visual Studio Code..."
# install extensions for vs code
# install python extension, jupyter, vscode-pdf
#python extension
code --install-extension ms-python.python
[ $? -ne 0 ] && exit_message

#jupyter extension
code --install-extension ms-toolsai.jupyter
[ $? -ne 0 ] && exit_message

#pdf extension (for viewing pdfs inside vs code)
code --install-extension tomoki1207.pdf
[ $? -ne 0 ] && exit_message

echo ""
echo "$_prefix Installed Visual Studio Code successfully!"
