#!/bin/bash
# @doc
# @name: VS Code Settings (macOS)
# @description: Apply default VS Code settings
# @category: Core
# @usage: bash Core/VsCode/config/settings_macOS.sh
# @requirements: macOS, VS Code installed
# @notes: Copies default_settings_MacOS.json to the VS Code user settings location
# @/doc

set -euo pipefail

settings_dir="$HOME/Library/Application Support/Code/User"
settings_file="$settings_dir/settings.json"

echo "=== Applying VS Code Settings ==="
echo ""

if [[ -e "$settings_file" ]]; then
  echo "  [ERROR] $settings_file already exists. Aborting to avoid overwrite." >&2
  exit 1
fi

mkdir -p "$settings_dir"
curl -fsSL "$PS_REPO_URL/Core/VsCode/config/default_settings_MacOS.json" > "$settings_file"
echo "  [OK] Settings applied to $settings_file"

echo ""
echo "=== VS Code settings complete! ==="
