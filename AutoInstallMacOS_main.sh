# checks for environmental variables for remote and branch 

if [ -z "$REMOTE_PS" ]; then
  REMOTE_PS="dtudk"
fi

if [ -z "$BRANCH_PS" ]; then
  BRANCH_PS="main"
fi

export REMOTE_PS
export BRANCH_PS

# set path 
path_ps="https://raw.githubusercontent.com/$REMOTE_PS/pythonsupport-scripts/$BRANCH_PS"
# links to full
export path_ps

# installs python
/bin/bash -c "$(curl -fsSL $path_ps/MacOSAuto_python.sh)"

# install vscode
/bin/bash -c "$(curl -fsSL $path_ps/MacOSAuto_VSC.sh)"


# links to placeholder
#

#/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/AutoInstallMacOS_placeholder.sh)"

