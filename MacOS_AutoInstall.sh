# checks for environmental variables for remote and branch 
if [ -z "$REMOTE_PS" ]; then
  REMOTE_PS="dtudk/pythonsupport-scripts"
fi
if [ -z "$BRANCH_PS" ]; then
  BRANCH_PS="main"
fi

export REMOTE_PS
export BRANCH_PS

# set URL
url_ps="https://raw.githubusercontent.com/$REMOTE_PS/$BRANCH_PS/MacOS"

# echo url for debugging
echo "URL used for fetching scripts $url_ps"

# install python
/bin/bash -c "$(curl -fsSL $url_ps/Python/Install.sh)"

# install vscode
/bin/bash -c "$(curl -fsSL $url_ps/VSC/Install.sh)"

clear -x

echo ""
echo "Script has finished. You may now close the terminal..."

