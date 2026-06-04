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

APP_PATH="/Applications/Visual Studio Code.app"
DOWNLOAD_URL="https://update.code.visualstudio.com/latest/darwin-universal/stable"

echo "=== Installing VS Code ==="
echo ""

# Check if already installed
if command -v code &>/dev/null || [ -d "$APP_PATH" ]; then
    echo "  VS Code is already installed."
    echo "  [OK] Skipping download"
else
    # Download
    TMPDIR_PATH="$(mktemp -d)"
    trap "rm -rf '$TMPDIR_PATH'" EXIT

    echo "  Downloading VS Code..."
    curl -fSL "$DOWNLOAD_URL" -o "$TMPDIR_PATH/VSCode.zip"
    echo "  [OK] Download complete"

    # Extract
    echo "  Extracting..."
    unzip -q "$TMPDIR_PATH/VSCode.zip" -d "$TMPDIR_PATH/vscode_extracted"
    echo "  [OK] Extraction complete"

    # Remove existing installation if present
    if [ -d "$APP_PATH" ]; then
        echo "  Removing existing installation..."
        if [ -w "$APP_PATH" ]; then
            rm -rf "$APP_PATH"
        else
            sudo rm -rf "$APP_PATH"
        fi
    fi

    # Move to /Applications
    echo "  Moving to /Applications..."
    mv "$TMPDIR_PATH/vscode_extracted/Visual Studio Code.app" "$APP_PATH"
    echo "  [OK] VS Code installed"
fi

# Apply settings
bash <(curl -fsSL "$REPO_BASE_URL/Core/VsCode/config/settings_macOS.sh")

# Install extensions
bash <(curl -fsSL "$REPO_BASE_URL/Core/VsCode/config/extensions_macOS.sh")

echo ""
echo "=== VS Code installation complete! ==="
