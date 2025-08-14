#!/bin/bash

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

url_ps="https://raw.githubusercontent.com/$REMOTE_PS/$BRANCH_PS/MacOS"

echo "$_prefix Python (Miniconda) installation"
echo "$_prefix Starting installation process..."

# Check for homebrew
# if not installed call homebrew installation script
if ! command -v brew > /dev/null; then
  echo "$_prefix Homebrew is not installed. Installing Homebrew..."
  echo "$_prefix Installing from $url_ps/Components/Homebrew/install.sh"
  /bin/bash -c "$(curl -fsSL $url_ps/Components/Homebrew/install.sh)"

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

# Install miniconda
# Check if miniconda is installed
echo "$_prefix Installing Miniconda..."
if conda --version > /dev/null; then
  echo "$_prefix Miniconda or anaconda is already installed"
else
  echo "$_prefix Miniconda or anaconda not found, installing Miniconda"
  brew install --cask miniconda
  [ $? -ne 0 ] && exit_message
fi
clear -x

echo "$_prefix Initialising conda..."
conda init bash
[ $? -ne 0 ] && exit_message

conda init zsh
[ $? -ne 0 ] && exit_message

# Anaconda has this package which tracks usage metrics
# We will disable this, and if it fails, so be it.
# I.e. we shouldn't check whether it actually succeeds
conda config --set anaconda_anon_usage off

# need to restart terminal to activate conda
# restart terminal and continue
# conda puts its source stuff in the bashrc file
[ -e ~/.bashrc ] && source ~/.bashrc

echo "$_prefix Showing where it is installed:"
conda info --base
[ $? -ne 0 ] && exit_message

echo "$_prefix Updating environment variables"
hash -r
clear -x

# We will not install the Anaconda GUI
# There may be license issues due to DTU being
# a rather big institution. So our installation guides
# will be pre-cautious here, and remove the defaults channels.
echo "$_prefix Removing defaults channel (due to licensing problems)"
conda config --remove channels defaults
conda config --add channels conda-forge

# Sadly, there can be a deadlock here
# When channel_priority == strict
# newer versions of conda will sometimes be unable to downgrade.
# However, when channel_priority == flexible
# it will sometimes not revert the libmamba suite which breaks
# the following conda install commands.
# Hmmm.... :(
conda config --set channel_priority flexible

echo ""
echo "$_prefix Installed Miniconda successfully!"