# checks for environmental variables for remote and branch 

if [ -z "$REMOTE_PS" ]; then

  REMOTE="dtudk"
fi

if [ -z "$BRANCH_PS" ]; then
  BRANCH="main"
fi

# set path 

path="https://raw.githubusercontent.com/$REMOTE/pythonsupport-scripts/$BRANCH"

# links to full


# installs python
/bin/bash -c "$(curl -fsSL $path/AutoInstallMacOS_python.sh)"

# install vscode
/bin/bash -c "$(curl -fsSL $path/AutoInstallMacOS_VSC.sh)"


# links to placeholder
#

#/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/AutoInstallMacOS_placeholder.sh)"

