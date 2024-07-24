# Error function 
# Print error message, contact information and exits script

exit_message () {
    echo "Oh no! Something went wrong"
    echo "Please try to install manually or contact the Python Support Team: pythonsupport@dtu.dk or visit us during our office hours"
}


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

clear -x

# First install homebrew 
echo "Installing Homebrew. Please following the intructions on the screen"

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Set environment variables


(echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> ~/.zshrc
(echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> ~/.bash_profile
eval "$(/usr/local/bin/brew shellenv)"
eval "$(/opt/homebrew/bin/brew shellenv)"
# update terminal 
hash -r 

# if homebrew is installed correctly proceed, otherwise exit
if brew help > /dev/null; then
    echo "Homebrew installed successfully"
else
    echo "Homebrew installation failed. Exiting"
    exit_message
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
conda init bash 
conda init zsh
# need to restart terminal to activate conda
# restart terminal and continue


# 'restart' terminal
eval "$(/usr/local/bin/brew shellenv)"

hash -r 
# Install anaconda GUI
echo "Installing Anaconda Navigator GUI"
conda install anaconda-navigator -y

conda install python=3.11 -y

conda install -c conda-forge dtumathtools uncertainties -y



# check if vs code is installed
# using multipleVersionsMac to check 
echo "Installing Visual Studio Code if not already installed"
# if output is empty, then install vs code
vspath=$(/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/multipleVersionsMac.sh)")
if [ -n "$vspath" ]  ; then
    echo "Visual Studio Code is already installed"
else
    echo "Installing Visual Studio Code"
    brew install --cask visual-studio-code
fi
hash -r 
echo "Installing extensions for Visual Studio Code"
eval "$(/usr/local/bin/brew shellenv)"

# Test if code is installed correctly
if code --version > /dev/null; then
    echo "Visual Studio Code installed successfully"
else
    echo "Visual Studio Code installation failed. Exiting"
    exit_message
    exit 1
fi

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


