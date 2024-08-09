# checks for environmental variables for remote and branch 

: "${REMOTE_PS:=dtudk}"

: "${BRANCH_PS:=main}"


# set path 
echo "Setting path"
path="https://raw.githubusercontent.com/$REMOTE_PS/pythonsupport-scripts/$BRANCH_PS"
echo $path
# links to full


# installs python
/bin/bash -c "$(curl -fsSL $path/MacOSAuto_python.sh)"

# install vscode
/bin/bash -c "$(curl -fsSL $path/MacOSAuto_VSC.sh)"


# links to placeholder
#

#/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/AutoInstallMacOS_placeholder.sh)"

