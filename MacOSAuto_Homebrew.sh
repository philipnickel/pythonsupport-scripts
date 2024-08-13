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

# check for homebrew
echo "Checking for existing homebrew installation..."

if command -v brew > /dev/null; then
  echo "Already found Homebrew, no need to install Homebrew..."
  exit 0
fi

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

