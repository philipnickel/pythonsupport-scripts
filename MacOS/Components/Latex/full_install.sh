#!/bin/bash

_prefix="PYS:"

echo "$_prefix LaTeX full installation"
echo "$_prefix This script will install comprehensive LaTeX dependencies for advanced PDF export from Jupyter Notebooks."
echo "$_prefix You will need to type your password to the computer at some point during the installation."
echo "$_prefix This script will take a while to run, please be patient, and don't close your terminal before it says 'script finished'."
sleep 1

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

echo "$_prefix Installing comprehensive TeX packages..."

# Comprehensive list of packages for full LaTeX functionality
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
    xcolor
    listings
    fancyhdr
    geometry
    hyperref
    graphicx
    booktabs
    longtable
    array
    multirow
    wrapfig
    float
    parskip
    setspace
    caption
    subcaption
    tikz
    pgfplots
    beamer
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

# Install all packages
for package in "${packages[@]}"; do
    install_package_with_retries $package
done

echo "$_prefix Updating all TeX packages - this may take a while..."
sudo tlmgr update --all > /dev/null
echo "$_prefix Finished updating TeX packages"

echo "$_prefix Installing/updating nbconvert..."
python3 -m pip install --force-reinstall nbconvert > /dev/null
echo "$_prefix nbconvert installation complete"

echo ""
echo "$_prefix LaTeX full installation completed!"
echo "$_prefix This comprehensive installation supports advanced features like TikZ, PGFPlots, Beamer presentations, and more."
echo "$_prefix Please make sure to restart Visual Studio Code for the changes to take effect."
echo "$_prefix If you have multiple versions of python installed and PDF exporting doesn't work, try running 'python3 -m pip install --force-reinstall nbconvert' for the version of python you are using in your notebook."
echo "$_prefix If it still doesn't work, try exporting via HTML first (Export as HTML and then convert to PDF using a browser)."
echo ""