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

# Install MacTeX (full LaTeX distribution) if not present
if ! command -v tlmgr &> /dev/null; then
    echo "$_prefix Installing MacTeX (full LaTeX distribution)..."
    echo "$_prefix This is a large download (~4GB) and may take a while..."
    curl -LJO https://mirrors.dotsrc.org/ctan/systems/mac/mactex/MacTeX.pkg > /dev/null
    sudo installer -pkg MacTeX.pkg -target / > /dev/null
    rm MacTeX.pkg
    echo "$_prefix MacTeX installation complete"
else
    echo "$_prefix TeX is already installed, skipping that step"
fi

hash -r 

echo "$_prefix MacTeX includes all packages, no additional packages needed"

# Check if Jupyter ecosystem is available and install if needed
echo "$_prefix Checking Jupyter ecosystem for PDF export..."

# Check if jupyter is available
if ! python3 -c "import jupyter" >/dev/null 2>&1; then
    echo "$_prefix Jupyter not found, installing Jupyter ecosystem..."
    python3 -m pip install --upgrade jupyter jupyterlab notebook >/dev/null 2>&1
    echo "$_prefix Jupyter ecosystem installed"
else
    echo "$_prefix Jupyter already available"
fi

# Check if nbconvert is available
if ! python3 -c "import nbconvert" >/dev/null 2>&1; then
    echo "$_prefix nbconvert not found, installing..."
    python3 -m pip install --upgrade nbconvert >/dev/null 2>&1
    echo "$_prefix nbconvert installed"
else
    echo "$_prefix nbconvert already available, updating..."
    python3 -m pip install --upgrade nbconvert >/dev/null 2>&1
fi

# Install essential packages for notebook functionality
echo "$_prefix Installing essential packages for notebook functionality..."
python3 -m pip install --upgrade ipykernel ipywidgets matplotlib >/dev/null 2>&1

# Install Python kernel for Jupyter
echo "$_prefix Setting up Python kernel for Jupyter..."
python3 -m ipykernel install --user --name python3 --display-name "Python 3" >/dev/null 2>&1 || true

echo "$_prefix Jupyter/nbconvert setup complete"

echo ""
echo "$_prefix LaTeX full installation completed!"
echo "$_prefix This comprehensive installation supports advanced features like TikZ, PGFPlots, Beamer presentations, and more."
echo "$_prefix Please make sure to restart Visual Studio Code for the changes to take effect."
echo "$_prefix If you have multiple versions of python installed and PDF exporting doesn't work, try running 'python3 -m pip install --force-reinstall nbconvert' for the version of python you are using in your notebook."
echo "$_prefix If it still doesn't work, try exporting via HTML first (Export as HTML and then convert to PDF using a browser)."
echo ""