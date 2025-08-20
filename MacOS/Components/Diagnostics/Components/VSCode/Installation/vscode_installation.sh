#!/bin/bash
# @name: VS Code Installation Check
# @description: Check if Visual Studio Code is properly installed
# @category: VSCode
# @subcategory: Installation
# @timeout: 8

echo "VS CODE INSTALLATION CHECK"
echo "=========================="

vscode_found=0

# Check if code command is available
if command -v code >/dev/null 2>&1; then
    code_path=$(which code)
    echo "✓ 'code' command is available"
    echo "  Location: $code_path"
    
    # Get VS Code version
    if version_info=$(code --version 2>/dev/null); then
        version=$(echo "$version_info" | head -1)
        echo "  Version: $version"
    else
        echo "  Version: Unable to determine version"
    fi
    
    vscode_found=1
else
    echo "✗ 'code' command not found in PATH"
fi

echo ""

# Check for VS Code in common macOS locations
echo "Application Check:"
echo "-----------------"
if [ -d "/Applications/Visual Studio Code.app" ]; then
    echo "✓ VS Code found in /Applications/"
    vscode_found=1
    
    if [ ! -x "$(command -v code)" ]; then
        echo "⚠ VS Code app found but 'code' command not in PATH"
        echo "  To fix: Open VS Code → View → Command Palette → 'Shell Command: Install code command'"
    fi
else
    echo "✗ VS Code not found in /Applications/"
fi

# Check for VS Code Insiders
if [ -d "/Applications/Visual Studio Code - Insiders.app" ]; then
    echo "✓ VS Code Insiders found in /Applications/"
    vscode_found=1
fi

echo ""

if [ $vscode_found -eq 1 ]; then
    echo "✅ VS Code installation check complete - PASSED"
else
    echo "❌ VS Code not found"
    echo ""
    echo "Installation options:"
    echo "• Download from: https://code.visualstudio.com/"
    echo "• Install via Homebrew: brew install --cask visual-studio-code"
    exit 1
fi