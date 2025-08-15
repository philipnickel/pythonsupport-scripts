#!/bin/bash

_prefix="PYS:"

echo "$_prefix LaTeX installation"
echo "$_prefix This script will install dependencies for exporting Jupyter Notebooks to PDF in Visual Studio Code."
echo "$_prefix You will need to type your password to the computer at some point during the installation."

# do you wish to continue? You will need to enter your password to the computer.
# Skip prompt in CI environments
if [[ -z "$CI" && -z "$GITHUB_ACTIONS" ]]; then
    read -p "Do you wish to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        echo "Script aborted."
        exit 1
    fi
else
    echo "Running in automated environment, skipping user prompt."
fi

echo "$_prefix This script will take a while to run, please be patient, and don't close your terminal before it says 'script finished'."
sleep 1

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

# check for pandoc
if ! command -v pandoc &> /dev/null; then
    # check for intel or apple silicon
    if [ "$(uname -m)" == "x86_64" ]; then
        echo "$_prefix Installing pandoc for Intel..."
        curl -LJO https://github.com/jgm/pandoc/releases/download/3.1.12.2/pandoc-3.1.12.2-x86_64-macOS.pkg > /dev/null
        sudo installer -pkg pandoc-3.1.12.2-x86_64-macOS.pkg -target / > /dev/null
        rm pandoc-3.1.12.2-x86_64-macOS.pkg
        echo "$_prefix Pandoc installation complete"
    else
        echo "$_prefix Installing pandoc for Apple Silicon..."
        curl -LJO https://github.com/jgm/pandoc/releases/download/3.1.12.2/pandoc-3.1.12.2-arm64-macOS.pkg > /dev/null
        sudo installer -pkg pandoc-3.1.12.2-arm64-macOS.pkg -target / > /dev/null
        rm pandoc-3.1.12.2-arm64-macOS.pkg
        echo "$_prefix Pandoc installation complete"
    fi
else
    echo "$_prefix Pandoc is already installed, skipping that step"
fi

# check if some version of TeX is installed
if ! command -v tlmgr &> /dev/null; then
    # install BasicTex 
    echo "$_prefix Installing BasicTeX..."
    curl -LJO https://mirrors.dotsrc.org/ctan/systems/mac/mactex/BasicTeX.pkg  > /dev/null
    sudo installer -pkg BasicTeX.pkg -target / > /dev/null
    rm BasicTeX.pkg
    echo "$_prefix BasicTeX installation complete"
else
    echo "$_prefix TeX is already installed, skipping that step"
fi

hash -r 

# check for existing tex-installation 
echo "$_prefix Updating TeX package manager..."
sudo tlmgr update --self > /dev/null
(
cd /usr/local/texlive/2023basic/
sudo chmod 777 tlpkg
)

echo "$_prefix Installing additional TeX packages..."

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
        echo "$_prefix Attempting to install $package (Attempt $attempt of $max_attempts)..."
        sudo tlmgr install $package > /dev/null

        if [ $? -eq 0 ]; then
            echo "$_prefix $package installed successfully."
            return 0
        else
            echo "$_prefix Failed to install $package. Retrying..."
            ((attempt++))
        fi
    done

    echo "$_prefix Failed to install $package after $max_attempts attempts."
    return 1
}

# Iterate over the list of packages and attempt to install each one
for package in "${packages[@]}"; do
    install_package_with_retries $package
done

echo "$_prefix Updating all TeX packages - this may take a while..."
sudo tlmgr update --all > /dev/null
echo "$_prefix Finished updating TeX packages"

echo "$_prefix Updating nbconvert..."
python3 -m pip install --force-reinstall nbconvert > /dev/null
echo "$_prefix Finished updating nbconvert"

echo ""
echo "$_prefix LaTeX installation completed!"
echo "$_prefix Please make sure to restart Visual Studio Code for the changes to take effect."
echo "$_prefix If you have multiple versions of python installed and PDF exporting doesn't work, try running 'python3 -m pip install --force-reinstall nbconvert' for the version of python you are using in your notebook."
echo "$_prefix If it still doesn't work, try exporting via HTML first (Export as HTML and then convert to PDF using a browser)."