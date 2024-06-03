echo "Script by Python Installation Support DTU"

echo "This script will install dependencies for exporting Jupyter Notebooks to PDF in Visual Studio Code."
echo "You will need to type your password to the computer at some point during the installation."
# do you wish to continue? You will need to enter your password to the computer.
read -p "Do you wish to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Script aborted."
    exit 1
fi


echo "This script will take a while to run, please be patient, and don't close your terminal before it says 'script finished'."
sleep 1

#


sleep 1 
# check for pandoc
if ! command -v pandoc &> /dev/null; then
    # check for intel or apple silicon
    if [ "$(uname -m)" == "x86_64" ]; then
        echo "installing pandoc for intel"
        curl -LJO https://github.com/jgm/pandoc/releases/download/3.1.12.2/pandoc-3.1.12.2-x86_64-macOS.pkg > /dev/null
        sudo installer -pkg pandoc-3.1.12.2-x86_64-macOS.pkg -target / > /dev/null
        rm pandoc-3.1.12.2-x86_64-macOS.pkg
        echo "Installation complete"
    else
        echo "installing pandoc for apple silicon"
        curl -LJO https://github.com/jgm/pandoc/releases/download/3.1.12.2/pandoc-3.1.12.2-arm64-macOS.pkg > /dev/null
        sudo installer -pkg pandoc-3.1.12.2-arm64-macOS.pkg -target / > /dev/null
        rm pandoc-3.1.12.2-arm64-macOS.pkg
        echo "Installation complete"
    fi
else
    echo "Pandoc is already installed, skipping that step"
fi


# check if some version of TeX is installed
if ! command -v tlmgr &> /dev/null; then
    # install BasicTex 
    echo "installing BasicTex"
    curl -LJO https://mirrors.dotsrc.org/ctan/systems/mac/mactex/BasicTeX.pkg  > /dev/null
    sudo installer -pkg BasicTeX.pkg -target / > /dev/null
    rm BasicTeX.pkg
    echo "Installation complete"
else
    echo "TeX is already installed, skipping that step"
fi

hash -r 



# check for exisisting tex-installation 

echo "Updating TeX package manager"
sudo tlmgr update --self > /dev/null
(
cd /usr/local/texlive/2023basic/
sudo chmod 777 tlpkg
)

echo "Installing additional TeX packages"

sudo tlmgr install 

# List of packages to install
packages=(
    amsmath
    amsfonts
    texliveonfly
    adjustbox
    tcolorbox
    collectbox
    ucs
    environ
    trimspaces
    titling
    enumitem
    rsfs
    pdfcol
    soul
    txfonts
)

# Maximum number of attempts to install each package
max_attempts=3

# Function to install a TeX package with retries
install_package_with_retries() {
    local package=$1
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        echo "Attempting to install $package (Attempt $attempt of $max_attempts)..."
        sudo tlmgr install $package > /dev/null

        if [ $? -eq 0 ]; then
            echo "$package installed successfully."
            return 0
        else
            echo "Failed to install $package. Retrying..."
            ((attempt++))
        fi
    done

    echo "Failed to install $package after $max_attempts attempts."
    return 1
}

# Iterate over the list of packages and attempt to install each one
for package in "${packages[@]}"; do
    install_package_with_retries $package
done

echo "Updating all TeX packages - this may take a while"
sudo tlmgr update --all > /dev/null
echo "Finished updating TeX packages"

echo "Updating nbconvert"
python3 -m pip3 install --force-reinstall nbconvert > /dev/null

echo "Finished updating nbconvert"

echo "Script finished."
echo "Please make sure to restart visual studio code for the changes to take effect."
echo "If you have multiple versions of python installed and pdf exporting doesn't work,  try running "python3 -m pip install --force-reinstall nbconvert" for the version of python you are using in your notebook. You can do this directly in the vs code terminal (terminal -> new terminal)"

echo "If it still doesn't work resolve to using pdf export via HTML (Export as HTML and then convert to pdf using a browser)."

