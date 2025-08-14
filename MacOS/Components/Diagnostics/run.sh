#!/bin/bash

_prefix="PYS:"

echo "$_prefix Running Python Support Diagnostics"
echo "$_prefix System analysis starting..."
echo "$_prefix Checking system compatibility..."
echo "========================================="
echo ""

# System Information
echo "SYSTEM INFORMATION"
echo "------------------"
echo "macOS Version: $(sw_vers -productVersion)"
echo "Architecture: $(uname -m)"
echo "Hostname: $(hostname)"
echo ""

# Homebrew Check
echo "HOMEBREW"
echo "--------"
if command -v brew > /dev/null; then
    echo "✓ Homebrew is installed"
    echo "  Version: $(brew --version | head -n 1)"
    echo "  Location: $(which brew)"
    
    # Check for common issues
    if brew doctor > /dev/null 2>&1; then
        echo "  Status: ✓ No issues found"
    else
        echo "  Status: ⚠ Issues found (run 'brew doctor' for details)"
    fi
else
    echo "✗ Homebrew is not installed"
fi
echo ""

# Python/Conda Check
echo "PYTHON/CONDA"
echo "-------------"
if command -v conda > /dev/null; then
    echo "✓ Conda is installed"
    echo "  Version: $(conda --version)"
    echo "  Location: $(which conda)"
    echo "  Base environment: $(conda info --base)"
    
    # Check active environment
    if [ -n "$CONDA_DEFAULT_ENV" ]; then
        echo "  Active environment: $CONDA_DEFAULT_ENV"
    else
        echo "  Active environment: None"
    fi
    
    # Check Python version in conda
    echo "  Python version: $(conda list python | grep "^python " | awk '{print $2}' || echo "Not found")"
    
    # Check for key packages
    echo "  Key packages:"
    for pkg in dtumathtools pandas scipy statsmodels uncertainties; do
        if conda list | grep -q "^$pkg "; then
            version=$(conda list | grep "^$pkg " | awk '{print $2}')
            echo "    ✓ $pkg ($version)"
        else
            echo "    ✗ $pkg"
        fi
    done
else
    echo "✗ Conda is not installed"
    
    # Check for system Python
    if command -v python3 > /dev/null; then
        echo "  System Python3: $(python3 --version)"
        echo "  Location: $(which python3)"
    fi
fi
echo ""

# Visual Studio Code Check
echo "VISUAL STUDIO CODE"
echo "------------------"
if command -v code > /dev/null; then
    echo "✓ Visual Studio Code is installed"
    echo "  Version: $(code --version | head -n 1)"
    echo "  Location: $(which code)"
    
    # Check for key extensions
    echo "  Key extensions:"
    for ext in ms-python.python ms-toolsai.jupyter tomoki1207.pdf; do
        if code --list-extensions | grep -q "^$ext$"; then
            echo "    ✓ $ext"
        else
            echo "    ✗ $ext"
        fi
    done
else
    echo "✗ Visual Studio Code is not installed"
    
    # Check for VS Code in common locations
    if [ -d "/Applications/Visual Studio Code.app" ]; then
        echo "  Found in Applications but not in PATH"
    fi
fi
echo ""

# LaTeX Check
echo "LATEX"
echo "-----"
if command -v tlmgr > /dev/null; then
    echo "✓ TeX Live is installed"
    echo "  Location: $(which tlmgr)"
    
    # Check for pandoc
    if command -v pandoc > /dev/null; then
        echo "✓ Pandoc is installed"
        echo "  Version: $(pandoc --version | head -n 1)"
    else
        echo "✗ Pandoc is not installed"
    fi
    
    # Check for nbconvert
    if python3 -c "import nbconvert" 2>/dev/null; then
        echo "✓ nbconvert is available"
    else
        echo "✗ nbconvert is not available"
    fi
else
    echo "✗ TeX Live is not installed"
fi
echo ""

# Shell Configuration Check
echo "SHELL CONFIGURATION"
echo "-------------------"
echo "Current shell: $SHELL"

# Check for conda initialization
if [ -f ~/.bashrc ] && grep -q "conda initialize" ~/.bashrc; then
    echo "✓ Conda initialized in ~/.bashrc"
fi

if [ -f ~/.zshrc ] && grep -q "conda initialize" ~/.zshrc; then
    echo "✓ Conda initialized in ~/.zshrc"
fi

# Check for homebrew in PATH
if [ -f ~/.zprofile ] && grep -q "brew shellenv" ~/.zprofile; then
    echo "✓ Homebrew configured in ~/.zprofile"
fi

if [ -f ~/.bash_profile ] && grep -q "brew shellenv" ~/.bash_profile; then
    echo "✓ Homebrew configured in ~/.bash_profile"
fi

echo ""
echo "========================================="
echo "$_prefix Diagnostics complete"