
#!/bin/bash

# Function to handle error messages
exit_message () {
    echo "Oh no! Something went wrong"
    echo "Please try to install manually or contact the Python Support Team:" 
    echo "Pythonsupport@dtu.dk"
    echo "Or visit us during our office hours"
    exit 1
}

# Function to display loading animation
loading_animation () {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Ask if the user wants to enable debugging
echo "Do you want to enable debugging mode? (y/n)"
read -r debug_mode

if [ "$debug_mode" == "y" ]; then
    DEBUG=true
else
    DEBUG=false
fi

# Function to execute commands with optional debugging
execute_command () {
    local cmd="$1"
    if $DEBUG; then
        eval "$cmd"
    else
        eval "$cmd" &> /dev/null &
        loading_animation $!
    fi

    if [ $? -ne 0 ]; then
        exit_message
    fi
}

# Welcome text
echo "Welcome to the MacOS Auto Installer Script"
echo "This script will install miniconda and Visual Studio Code on your MacOS"
echo "Please don't close the terminal until the installation is complete"
echo "This might take a while depending on your internet connection and what dependencies need to be installed"
echo "The script will take at least 5 minutes to complete depending on your internet connection and computer..."
sleep 3
clear -x

# Install Homebrew
echo "Installing Homebrew... "
execute_command 'yes | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

clear -x 

echo "Setting environment variables..."
# Set environment variables

# Check if brew is in /usr/local/bin/ or /opt/homebrew/bin 
# and set the shellenv accordingly
# as well as add the shellenv to the shell profile

if [ -f /usr/local/bin/brew ]; then
    echo "Brew is installed in /usr/local/bin"
    (echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> ~/.zprofile
    (echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> ~/.bash_profile
    eval "$(/usr/local/bin/brew shellenv)"
elif [ -f /opt/homebrew/bin/brew ]; then
    echo "Brew is installed in /opt/homebrew/bin"
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.bash_profile
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "Brew is not installed correctly. Exiting"
    exit_message
fi

clear -x

# update terminal 
hash -r 

# if homebrew is installed correctly proceed, otherwise exit
if brew help > /dev/null; then
    echo "Homebrew installed successfully"
else
    echo "Homebrew installation failed. Exiting"
    exit_message
fi

# Install Miniconda
echo "Installing Miniconda..."
if conda --version > /dev/null; then
    echo "Miniconda or Anaconda is already installed"
else
    echo "Installing Miniconda"
    execute_command "brew install --cask miniconda"
fi
clear -x

echo "Initialising conda..."
# Initialize conda
execute_command "conda init bash"
execute_command "conda init zsh"

# 'restart' terminal
eval "$(/usr/local/bin/brew shellenv)"

hash -r 
clear -x

# Install Anaconda Navigator GUI
echo "Installing Anaconda Navigator GUI"
execute_command "conda install anaconda-navigator -y"

# Downgrade Python version to 3.11
echo "Downgrading Python version to 3.11..."
execute_command "conda install python=3.11 -y"
clear -x 

# Install necessary packages
echo "Installing packages..."
execute_command "conda install -c conda-forge dtumathtools uncertainties -y"
clear -x

# Install Visual Studio Code if not already installed
echo "Installing Visual Studio Code if not already installed..."
vspath=$(/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/multipleVersionsMac.sh)")
if [ $? -ne 0 ]; then
    exit_message
fi

if [ -n "$vspath" ]; then
    echo "Visual Studio Code is already installed"
else
    echo "Installing Visual Studio Code"
    execute_command "brew install --cask visual-studio-code"
fi

hash -r 
clear -x

# Install extensions for Visual Studio Code
echo "Installing extensions for Visual Studio Code..."
execute_command "code --install-extension ms-python.python"
execute_command "code --install-extension ms-toolsai.jupyter"
execute_command "code --install-extension tomoki1207.pdf"

hash -r 

echo "Script has finished. You may now close the terminal"
