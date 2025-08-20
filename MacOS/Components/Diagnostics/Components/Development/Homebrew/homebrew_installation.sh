#!/bin/bash
# @name: Homebrew Installation Check
# @description: Check if Homebrew is properly installed and configured
# @category: Development
# @subcategory: Homebrew
# @timeout: 10

echo "HOMEBREW INSTALLATION CHECK"
echo "==========================="

# Check if Homebrew is installed
if command -v brew >/dev/null 2>&1; then
    brew_path=$(which brew)
    echo "✓ Homebrew is installed"
    echo "  Location: $brew_path"
    
    # Get Homebrew version
    if version_info=$(brew --version 2>/dev/null); then
        version=$(echo "$version_info" | head -1)
        echo "  Version: $version"
    else
        echo "  Version: Unable to determine version"
    fi
    
    echo ""
    
    # Check Homebrew configuration
    echo "Homebrew Configuration:"
    echo "----------------------"
    if brew --prefix >/dev/null 2>&1; then
        prefix=$(brew --prefix 2>/dev/null)
        echo "Prefix: $prefix"
    fi
    
    if brew --repository >/dev/null 2>&1; then
        repo=$(brew --repository 2>/dev/null)
        echo "Repository: $repo"
    fi
    
    echo ""
    echo "✅ Homebrew installation check complete - PASSED"
    echo ""
    echo "Note: Run 'brew doctor' manually for detailed health check"
else
    echo "✗ Homebrew is not installed"
    echo ""
    echo "Installation command:"
    echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    echo ""
    echo "❌ Homebrew not found - INSTALLATION NEEDED"
    exit 1
fi