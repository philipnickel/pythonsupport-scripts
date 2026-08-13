#!/bin/bash
# @doc
# @name: VS Code Extensions (macOS)
# @description: Install VS Code extensions from extensions.txt
# @category: Core
# @usage: bash Core/VsCode/config/extensions_macOS.sh
# @requirements: macOS, VS Code installed
# @notes: Reads extension IDs from extensions.txt (one per line, # comments and blank lines skipped)
# @/doc

set -euo pipefail

std_code_cli="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

echo "=== Installing VS Code Extensions ==="
echo ""

if [ ! -x "$std_code_cli" ]; then
    code_cli=$(command -v code 2>/dev/null || true)

    if [ ! -x "$code_cli" ]; then
        echo "  ERROR: VS Code not found at $std_code_cli"
        exit 1
    fi
else
    code_cli="$std_code_cli"
fi

while IFS= read -r line || [ -n "$line" ]; do
    [[ -z "$line" || "$line" == \#* ]] && continue

    if "$code_cli" --install-extension "$line" --force 2>/dev/null; then
        echo "  [OK] $line"
    else
        echo "  [FAIL] $line"
    fi
done < <(curl -fsSL "$PS_REPO_URL/Core/VsCode/config/extensions.txt")

echo ""
echo "=== Extensions complete! ==="
