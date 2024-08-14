
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



Echo "get's to python installation"
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

if [ -z "$PYTHON_VERSION_PS" ]; then
    PYTHON_VERSION_PS="3.11"
fi

_py_version=$PYTHON_VERSION_PS

# Install miniconda
# Check if miniconda is installed

echo "Installing Miniconda..."
if conda --version > /dev/null; then
    echo "Miniconda or anaconda is already installed"
else
    brew install --cask miniconda 
    [ $? -ne 0 ] && exit_message
fi
clear -x


echo "Initialising conda..."
conda init bash 
[ $? -ne 0 ] && exit_message

conda init zsh
[ $? -ne 0 ] && exit_message

# need to restart terminal to activate conda
# restart terminal and continue

# 'restart' terminal
eval "$($brew_path shellenv)"

hash -r 
clear -x

echo "Downgrading python version to ${_py_version}..."
conda install python=${_py_version} -y
[ $? -ne 0 ] && exit_message
clear -x 

# Install anaconda GUI
echo "Installing Anaconda Navigator GUI"
conda install anaconda-navigator -y
[ $? -ne 0 ] && exit_message

echo "Installing packages..."
conda install -c conda-forge dtumathtools uncertainties -y
[ $? -ne 0 ] && exit_message
clear -x

