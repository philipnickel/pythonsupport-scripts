
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
  echo "Homebrew is not installed. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL $url_ps/Homebrew/Install.sh)"
fi


# Error function 
# Print error message, contact information and exits script
exit_message () {
    echo ""
    echo "Oh no! Something went wrong"
    echo "Please try to install manually or contact the Python Support Team:" 
    echo ""
    echo "  pythonsupport@dtu.dk"
    echo ""
    echo "Or visit us during our office hours"
    exit 1
}

# check if vs code is installed
# using multipleVersionsMac to check 
echo "Installing Visual Studio Code if not already installed..."
# if output is empty, then install vs code
vspath=$(/bin/bash -c "$(curl -fsSL $url_ps/multipleVersionsMac.sh)")
[ $? -ne 0 ] && exit_message

if [ -n "$vspath" ]  ; then
    echo "Visual Studio Code is already installed"
else
    echo "Installing Visual Studio Code"
    brew install --cask visual-studio-code
    [ $? -ne 0 ] && exit_message
fi

hash -r 
clear -x


echo "Installing extensions for Visual Studio Code"
eval "$($brew_path shellenv)"

# Test if code is installed correctly
if code --version > /dev/null; then
    echo "Visual Studio Code installed successfully"
else
    echo "Visual Studio Code installation failed. Exiting"
    exit_message
fi
clear -x

echo "Installing extensions for Visual Studio Code..."
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
echo "Script has finished. You may now close the terminal..."
