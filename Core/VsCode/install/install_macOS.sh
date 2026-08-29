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
    tmpdir_path="$(mktemp -d)"
    trap "rm -rf '$tmpdir_path'" EXIT
    if [[ "${PS_OFFLINE:-0}" == "1" ]]; then
        vscode_archive="${PS_BUNDLE_ROOT:?PS_BUNDLE_ROOT is required in offline mode}/bundle_assets/vscode/macos-universal/VSCode.zip"
        [[ -f "$vscode_archive" ]] || {
            echo "Missing offline VS Code archive: $vscode_archive" >&2
            exit 1
        }
        echo "  Using bundled VS Code archive"
    else
        vscode_archive="$tmpdir_path/VSCode.zip"
        echo "  Downloading VS Code..."
        curl -fSL "$download_url" -o "$vscode_archive"
        echo "  [OK] Download complete"
    fi

    # Extract
    echo "  Extracting..."
    unzip -q "$vscode_archive" -d "$tmpdir_path/vscode_extracted"
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
if [[ "${PS_OFFLINE:-0}" == "1" ]]; then
    /bin/bash "${PS_BUNDLE_ROOT:?}/Core/VsCode/config/settings_macOS.sh"
else
    /bin/bash <(curl -fsSL "$PS_REPO_URL/Core/VsCode/config/settings_macOS.sh")
fi

# Install extensions
if [[ "${PS_OFFLINE:-0}" == "1" ]]; then
    /bin/bash "${PS_BUNDLE_ROOT:?}/Core/VsCode/config/extensions_macOS.sh"
else
    /bin/bash <(curl -fsSL "$PS_REPO_URL/Core/VsCode/config/extensions_macOS.sh")
fi

echo ""
echo "=== VS Code installation complete! ==="
