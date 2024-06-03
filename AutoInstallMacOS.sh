# Script installs miniconda and vs code 
# Welcome text 

echo "Welcome to the MacOS Auto Installer Script"
echo "This script will install miniconda and Visual Studio Code on your MacOS"
echo "Please don't close the terminal until the installation is complete"
echo "This might take a while depending on your internet connection and what dependencies needs to be installed"
# Do you want to continue?
read -p "Do you want to continue? (y/n): " choice

if [ $choice == "y" ]; then
    echo "Continuing with the installation"
else
    echo "Exiting the installation"
    exit 1
fi


# First install homebrew 
echo "Installing Homebrew. Please following the intructions on the screen"

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Set environment variables


(echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> ~/.zshrc
(echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> ~/.bash_profile
eval "$(/usr/local/bin/brew shellenv)"

# update terminal 
hash -r 

# if homebrew is installed correctly proceed, otherwise exit
if brew help > /dev/null; then
    echo "Homebrew installed successfully"
else
    echo "Homebrew installation failed. Exiting"
    exit 1
fi

# Install miniconda
# Check if miniconda is installed

echo "Installing Miniconda"
if conda --version > /dev/null; then
    echo "Miniconda or anaconda is already installed"
else
    echo "Installing Miniconda"
    brew install --cask miniconda 
fi

# Finally downgrade python version of base environment to 3.11
conda init 
# need to restart terminal to activate conda
# restart terminal and continue


# 'restart' terminal
eval "$(/usr/local/bin/brew shellenv)"

hash -r 
# Install anaconda GUI
echo "Installing Anaconda Navigator GUI"
conda install anaconda-navigator --yes

# Check if python version is 3.11
# if not, downgrade python version to 3.11
if python --version | grep "3.11" > /dev/null; then
    echo "Python version is 3.11"
else
    echo "Downgrading python version to 3.11"
    conda install python=3.11 --yes
fi
# check if vs code is installed
# using multipleVersionsMac to check 
echo "Installing Visual Studio Code if not already installed"
# if output is empty, then install vs code
vspath=$(/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/multipleVersionsMac.sh)")
echo "vspath= '$vspath'"
if $vspath = "''" ; then
    echo "Visual Studio Code is already installed"
else
    echo "Installing Visual Studio Code"
    brew install --cask visual-studio-code
fi
hash -r 
echo "Installing extensions for Visual Studio Code"
eval "$(/usr/local/bin/brew shellenv)"

# install extensions for vs code
# install python extension, jupyter, vscode-pdf
#python extension
code --install-extension ms-python.python
#jupyter extension
code --install-extension ms-toolsai.jupyter
#pdf extension (for viewing pdfs inside vs code)
code --install-extension tomoki1207.pdf

hash -r 

echo "Script has finished"


