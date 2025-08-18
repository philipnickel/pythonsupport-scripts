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

# Welcome text 
echo "Welcome to Python supports MacOS Auto Homebrew Installer Script"
echo ""
echo "This script will install Homebrew MacOS"
echo ""
echo "Please do not close the terminal until the installation is complete"
echo "This might take a while depending on your internet connection and what dependencies needs to be installed"
echo "The script will take at least 5 minutes to complete depending on your internet connection and computer..."
sleep 3
clear -x

# check for homebrew
echo "Checking for existing Homebrew installation..."

if command -v brew > /dev/null; then
  echo "Already found Homebrew, no need to install Homebrew..."
  exit 0
fi

# First install homebrew 
echo "Installing Homebrew..."
echo ""
echo "This will require you to type your password in the terminal."
echo "For security reasons you will not see what you type... It will be hidden while typing!"
echo ""

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

# update binary locations 
hash -r 

# if homebrew is installed correctly proceed, otherwise exit
if brew help > /dev/null; then
    echo ""
    echo "Installed Homebrew successfully!"
else
    echo "Homebrew installation failed. Exiting..."
    exit_message
fi

