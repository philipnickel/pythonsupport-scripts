#!/bin/bash
# @doc
# @name: Install required VS Code extensions
# @description: Install required extensions from the VS Code Marketplace (internet required)
# @category: Core
# @usage: bash "Install macOS.command" install-vscode
# @requirements: macOS, VS Code installed, internet connection
# @notes: Reads extension IDs from extensions.txt; VS Code resolves versions and dependencies
# @/doc

set -euo pipefail

if [[ "${PS_ENV_INITIALIZED:-0}" != "1" ]]; then
    echo "Environment is not initialized. Use Install macOS.command or install_all_macOS.sh." >&2
    exit 2
fi

std_code_cli="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

echo "=== Installing VS Code Extensions (internet required) ==="
echo ""

code_cli="$(command -v code 2>/dev/null || true)"
if [[ ! -x "$code_cli" && -x "$std_code_cli" ]]; then
    code_cli="$std_code_cli"
fi
if [[ ! -x "$code_cli" ]]; then
    echo "VS Code CLI not found. Is VS Code installed?" >&2
    exit 1
fi

if [[ "$PS_ENV" == "offline" ]]; then
    extensions_file="${PS_BUNDLE_ROOT:?PS_BUNDLE_ROOT is required in offline mode}/Core/VsCode/config/extensions.txt"
else
    extensions_file="$(mktemp)"
    trap 'rm -f "$extensions_file"' EXIT
    curl -fsSL "$PS_REPO_URL/Core/VsCode/config/extensions.txt" -o "$extensions_file"
fi

[[ -f "$extensions_file" ]] || {
    echo "Missing extension list: $extensions_file" >&2
    exit 1
}

failed_extensions=()
while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    if "$code_cli" --install-extension "$line" --force; then
        echo "  [OK] $line"
    else
        echo "  [FAIL] $line" >&2
        failed_extensions+=("$line")
    fi
done < "$extensions_file"

if (( ${#failed_extensions[@]} > 0 )); then
    echo "Could not install extension(s): ${failed_extensions[*]}" >&2
    echo "Connect to the internet and run the VS Code setup again." >&2
    exit 1
fi

echo ""
echo "=== Extensions complete! ==="
