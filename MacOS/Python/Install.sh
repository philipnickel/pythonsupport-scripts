
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


echo "Python installation"

# Check for homebrew
# if not installed call homebrew installation script
if ! command -v brew > /dev/null; then
  echo "Homebrew is not installed. Installing Homebrew..."
  echo "Installing from $url_ps/Homebrew/Install.sh"
  /bin/bash -c "$(curl -fsSL $url_ps/Homebrew/Install.sh)"

  # The above will install everything in a subshell.
  # So just to be sure we have it on the path
  source ~/.bash_profile

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
# conda puts its source stuff in the bashrc file
source ~/.bashrc

hash -r 
clear -x

echo "Removing defaults channel (due to licensing problems)"
conda config --add channels conda-forge
conda config --remove channels defaults


echo "Ensuring Python version ${_py_version}..."
conda install python=${_py_version} -y
[ $? -ne 0 ] && exit_message
clear -x 

# We will not install the Anaconda GUI
# There may be license issues due to DTU being
# a rather big institution. So our installation guides
# Will be pre-cautious here, and remove the defaults channels.

echo "Installing packages..."
conda install dtumathtools pandas scipy statsmodels uncertainties -y
[ $? -ne 0 ] && exit_message
clear -x

