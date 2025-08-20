#!/bin/bash
# @doc
# @name: LaTeX Minimal Installer
# @description: Installs BasicTeX with essential packages for PDF export from Jupyter notebooks
# @category: LaTeX
# @requires: macOS, Internet connection, Administrator privileges, Python with nbconvert
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Latex/minimal_install.sh)"
# @example: ./minimal_install.sh
# @notes: Installs BasicTeX (~100MB) plus essential packages from original install.sh. Designed for basic PDF export functionality from Jupyter notebooks in VS Code. For advanced LaTeX features, use full_install.sh instead.
# @author: Python Support Team
# @version: 2024-08-18
# @/doc

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

# Setup conda environment if available
if command -v conda >/dev/null 2>&1; then
    echo "$_prefix Setting up conda environment for Jupyter installation..."
    eval "$(conda shell.bash hook)" 2>/dev/null || true
    # Try to activate the base environment
    conda activate base 2>/dev/null || true
fi

# Check if Jupyter ecosystem is available and install if needed
echo "$_prefix Checking Jupyter ecosystem for PDF export..."

# Determine which pip to use (prefer conda's pip if available)
PIP_CMD="python3 -m pip"
if command -v conda >/dev/null 2>&1; then
    echo "$_prefix Using conda environment for package installation"
    # Install using conda first, then pip for missing packages
    conda install -y jupyter nbconvert ipykernel >/dev/null 2>&1 || echo "$_prefix Conda install failed, falling back to pip"
fi

# Check if jupyter is available and install if not
if ! python3 -c "import jupyter" >/dev/null 2>&1; then
    echo "$_prefix Jupyter not found, installing Jupyter ecosystem..."
    $PIP_CMD install --upgrade --user jupyter jupyterlab notebook >/dev/null 2>&1
    echo "$_prefix Jupyter ecosystem installed"
else
    echo "$_prefix Jupyter already available"
fi

# Check if nbconvert is available and install if not
if ! python3 -c "import nbconvert" >/dev/null 2>&1; then
    echo "$_prefix nbconvert not found, installing..."
    $PIP_CMD install --upgrade --user nbconvert >/dev/null 2>&1
    echo "$_prefix nbconvert installed"
else
    echo "$_prefix nbconvert already available, updating..."
    $PIP_CMD install --upgrade --user nbconvert >/dev/null 2>&1
fi

# Install essential packages for notebook functionality
echo "$_prefix Installing essential packages for notebook functionality..."
$PIP_CMD install --upgrade --user ipykernel ipywidgets matplotlib >/dev/null 2>&1

# Install Python kernel for Jupyter
echo "$_prefix Setting up Python kernel for Jupyter..."
python3 -m ipykernel install --user --name python3 --display-name "Python 3" >/dev/null 2>&1 || true

# Verify installation
echo "$_prefix Verifying Jupyter installation..."
if python3 -c "import jupyter" >/dev/null 2>&1; then
    echo "$_prefix ✓ Jupyter available"
else
    echo "$_prefix ✗ Jupyter not available after installation"
fi

if python3 -c "import nbconvert" >/dev/null 2>&1; then
    echo "$_prefix ✓ nbconvert available"
else
    echo "$_prefix ✗ nbconvert not available after installation"
fi

echo "$_prefix Jupyter/nbconvert setup complete"

echo ""
echo "$_prefix LaTeX minimal installation completed!"
echo "$_prefix This installation includes basic packages for PDF export from Jupyter notebooks."
echo "$_prefix Please restart Visual Studio Code for the changes to take effect."
echo ""