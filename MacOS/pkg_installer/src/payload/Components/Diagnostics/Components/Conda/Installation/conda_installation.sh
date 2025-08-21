#!/bin/bash
# @name: Conda Installation Check
# @description: Check if Conda is properly installed and accessible
# @category: Conda
# @subcategory: Installation
# @timeout: 10

echo "CONDA INSTALLATION CHECK"
echo "========================"

# Check if Conda is installed
conda_path=$(which conda 2>/dev/null)

if [ -z "$conda_path" ]; then
    echo "FAIL Conda is not installed"
    echo ""
    echo "Conda installation not found in PATH"
    echo ""
    echo "Installation options:"
    echo "• Install Miniconda: https://docs.conda.io/en/latest/miniconda.html"
    echo "• Install Anaconda: https://www.anaconda.com/products/individual"
    exit 1
else
    echo "PASS Conda is installed"
    echo "  Location: $conda_path"
    
    # Get conda version
    if conda --version > /dev/null 2>&1; then
        version=$(conda --version 2>/dev/null | head -1)
        echo "  Version: $version"
    else
        echo "  Version: Unable to determine version"
        exit 1
    fi
    
    echo ""
    
    # Basic conda functionality test
    echo "Functionality Test:"
    echo "------------------"
    if conda info > /dev/null 2>&1; then
        echo "PASS conda info command works"
    else
        echo "FAIL conda info command failed"
        exit 1
    fi
    
    if conda list > /dev/null 2>&1; then
        echo "PASS conda list command works"
    else
        echo "FAIL conda list command failed"
        exit 1
    fi
    
    echo ""
    echo "PASSED Conda installation check complete - PASSED"
fi