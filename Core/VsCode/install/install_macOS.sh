#!/bin/bash
# @doc
# @name: VS Code Install (macOS)
# @description: Download and install VS Code on macOS
# @category: Core
# @usage: bash Core/VsCode/install/install_macOS.sh
# @requirements: macOS, curl, unzip
# @notes: Downloads the universal binary, installs to /Applications, and adds 'code' to PATH
# @/doc

set -euo pipefail

app_path="/Applications/Visual Studio Code.app"
download_url="https://update.code.visualstudio.com/latest/darwin-universal/stable"

echo "=== Installing VS Code ==="
echo ""

# Check if already installed
if command -v code &>/dev/null || [ -d "$app_path" ]; then
    echo "  VS Code is already installed."
    echo "  [OK] Skipping download"
else
    # Download
    tmpdir_path="$(mktemp -d)"
    trap "rm -rf '$tmpdir_path'" EXIT

    echo "  Downloading VS Code..."
    curl -fSL "$download_url" -o "$tmpdir_path/VSCode.zip"
    echo "  [OK] Download complete"

    # Extract
    echo "  Extracting..."
    unzip -q "$tmpdir_path/VSCode.zip" -d "$tmpdir_path/vscode_extracted"
    echo "  [OK] Extraction complete"

    # Remove existing installation if present
    if [ -d "$app_path" ]; then
        echo "  Removing existing installation..."
        if [ -w "$app_path" ]; then
            rm -rf "$app_path"
        else
            sudo rm -rf "$app_path"
        fi
    fi

    # Move to /Applications
    echo "  Moving to /Applications..."
    mv "$tmpdir_path/vscode_extracted/Visual Studio Code.app" "$app_path"
    echo "  [OK] VS Code installed"
fi

# Apply settings
bash <(curl -fsSL "$PS_REPO_URL/Core/VsCode/config/settings_macOS.sh")

# Install extensions
bash <(curl -fsSL "$PS_REPO_URL/Core/VsCode/config/extensions_macOS.sh")

echo ""
echo "=== VS Code installation complete! ==="
