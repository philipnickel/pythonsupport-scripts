#!/bin/bash
# @doc
# @name: VS Code Install (macOS)
# @description: Download and install VS Code on macOS
# @category: Core
# @usage: bash "Install macOS.command" install-vscode
# @requirements: macOS, curl, unzip
# @notes: Downloads the universal binary, installs to /Applications, and adds 'code' to PATH
# @/doc

set -euo pipefail

if [[ "${PS_ENV_INITIALIZED:-0}" != "1" ]]; then
    echo "Environment is not initialized. Use Install macOS.command or install_all_macOS.sh." >&2
    exit 2
fi

app_path="/Applications/Visual Studio Code.app"

echo "=== Installing VS Code ==="
echo ""

# Check if already installed
if command -v code &>/dev/null || [ -d "$app_path" ]; then
    echo "  VS Code is already installed."
    echo "  [OK] Skipping download"
else
    tmpdir_path="$(mktemp -d)"
    trap "rm -rf '$tmpdir_path'" EXIT
    if [[ "$PS_ENV" == "offline" ]]; then
        vscode_archive="${PS_BUNDLE_ROOT:?PS_BUNDLE_ROOT is required in offline mode}/bundle_assets/vscode/macos-universal/VSCode.zip"
        [[ -f "$vscode_archive" ]] || {
            echo "Missing offline VS Code archive: $vscode_archive" >&2
            exit 1
        }
        echo "  Using bundled VS Code archive"
    else
        vscode_archive="$tmpdir_path/VSCode.zip"
        echo "  Downloading VS Code..."
        curl -fSL "${PS_VSCODE_URL:?PS_VSCODE_URL is required online}" -o "$vscode_archive"
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

echo ""
echo "=== VS Code installation complete! ==="
