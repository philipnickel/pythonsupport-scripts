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

# Script installs miniconda and vs code 
# Welcome text 
echo "Welcome to Python supports MacOS Auto Installer Script"
echo ""
echo "This script will install miniconda and Visual Studio Code on your MacOS"
echo ""
echo "Please do not close the terminal until the installation is complete"
echo "This might take a while depending on your internet connection and what dependencies needs to be installed"
echo "The script will take at least 5 minutes to complete depending on your internet connection and computer..."
sleep 3
clear -x

_py_version=3.11

# First install homebrew 
echo "Installing Homebrew..."

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
[ $? -ne 0 ] && exit_message


clear -x 

echo "Setting environment variables..."
# Set environment variables

# Check if brew is in /usr/local/bin/ or /opt/homebrew/bin 
# and set the shellenv accordingly
# as well as add the shellenv to the shell profile

if [ -f /usr/local/bin/brew ]; then
    brew_path=/usr/local/bin/brew
    echo "Brew is installed in /usr/local/bin"
    (echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> ~/.zprofile
    (echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> ~/.bash_profile
elif [ -f /opt/homebrew/bin/brew ]; then
    brew_path=/opt/homebrew/bin/brew
    echo "Brew is installed in /opt/homebrew/bin"
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.bash_profile
else
    echo "Brew is not installed correctly. Exiting"
    exit_message
fi
eval "$($brew_path shellenv)"

clear -x

# update terminal 
hash -r 

# if homebrew is installed correctly proceed, otherwise exit
if brew help > /dev/null; then
    echo "Homebrew installed successfully!"
else
    echo "Homebrew installation failed. Exiting..."
    exit_message
fi

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

# check if vs code is installed
# using multipleVersionsMac to check 
echo "Installing Visual Studio Code if not already installed..."
# if output is empty, then install vs code
vspath=$(/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/multipleVersionsMac.sh)")
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
