#!/bin/bash
# @doc
# @name: Uninstall VS Code
# @description: Uninstall VS Code and remove all user data on macOS
# @category: Utilities
# @usage: bash "Install macOS.command" uninstall-vscode
# @requirements: macOS
# @notes: Removes app, settings, extensions, and user data
# @/doc

set -euo pipefail

if [[ "${PS_ENV_INITIALIZED:-0}" != "1" ]]; then
    echo "Environment is not initialized. Use Install macOS.command." >&2
    exit 2
fi

app_path="/Applications/Visual Studio Code.app"
config_dir="$HOME/Library/Application Support/Code"
vscode_dir="$HOME/.vscode"

echo "=== Uninstalling VS Code ==="
echo ""

removed_something=false

# Remove application
if [ -d "$app_path" ]; then
    echo "  Found VS Code at $app_path"
    if [ -w "$app_path" ]; then
        rm -rf "$app_path"
    else
        sudo rm -rf "$app_path"
    fi
    echo "  [OK] Application removed"
    removed_something=true
else
    echo "  VS Code not found at /Applications"
fi

# Remove settings and extensions
if [ -d "$config_dir" ]; then
    rm -rf "$config_dir"
    echo "  [OK] Settings and extensions removed"
    removed_something=true
fi

# Remove user data
if [ -d "$vscode_dir" ]; then
    rm -rf "$vscode_dir"
    echo "  [OK] User data (~/.vscode) removed"
    removed_something=true
fi

echo ""
if [ "$removed_something" = true ]; then
    echo "=== Uninstall complete! ==="
else
    echo "No changes made - VS Code not found."
fi
