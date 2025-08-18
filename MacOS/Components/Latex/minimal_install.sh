#!/bin/bash

_prefix="PYS:"

echo "$_prefix LaTeX minimal installation"
echo "$_prefix This script will install minimal dependencies for exporting Jupyter Notebooks to PDF in Visual Studio Code."
echo "$_prefix You will need to type your password to the computer at some point during the installation."

# Error function 
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

# Install pandoc if not present
if ! command -v pandoc &> /dev/null; then
    echo "$_prefix Installing pandoc..."
    if [ "$(uname -m)" == "x86_64" ]; then
        echo "$_prefix Installing pandoc for Intel..."
        curl -LJO https://github.com/jgm/pandoc/releases/download/3.1.12.2/pandoc-3.1.12.2-x86_64-macOS.pkg > /dev/null
        sudo installer -pkg pandoc-3.1.12.2-x86_64-macOS.pkg -target / > /dev/null
        rm pandoc-3.1.12.2-x86_64-macOS.pkg
    else
        echo "$_prefix Installing pandoc for Apple Silicon..."
        curl -LJO https://github.com/jgm/pandoc/releases/download/3.1.12.2/pandoc-3.1.12.2-arm64-macOS.pkg > /dev/null
        sudo installer -pkg pandoc-3.1.12.2-arm64-macOS.pkg -target / > /dev/null
        rm pandoc-3.1.12.2-arm64-macOS.pkg
    fi
    echo "$_prefix Pandoc installation complete"
else
    echo "$_prefix Pandoc is already installed, skipping that step"
fi

# Install BasicTeX if not present
if ! command -v tlmgr &> /dev/null; then
    echo "$_prefix Installing BasicTeX..."
    curl -LJO https://mirrors.dotsrc.org/ctan/systems/mac/mactex/BasicTeX.pkg > /dev/null
    sudo installer -pkg BasicTeX.pkg -target / > /dev/null
    rm BasicTeX.pkg
    echo "$_prefix BasicTeX installation complete"
else
    echo "$_prefix TeX is already installed, skipping that step"
fi

hash -r 

# Update TeX package manager
echo "$_prefix Updating TeX package manager..."
sudo tlmgr update --self > /dev/null
(
cd /usr/local/texlive/2024basic/ || cd /usr/local/texlive/2023basic/
sudo chmod 777 tlpkg
)

echo "$_prefix Installing essential TeX packages for PDF export..."

# Essential packages for PDF export (from original install.sh)
essential_packages=(
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

# Install essential packages
for package in "${essential_packages[@]}"; do
    install_package_with_retries $package
done

echo "$_prefix Installing/updating nbconvert..."
python3 -m pip install --force-reinstall nbconvert > /dev/null
echo "$_prefix nbconvert installation complete"

echo ""
echo "$_prefix LaTeX minimal installation completed!"
echo "$_prefix This installation includes basic packages for PDF export from Jupyter notebooks."
echo "$_prefix Please restart Visual Studio Code for the changes to take effect."
echo ""