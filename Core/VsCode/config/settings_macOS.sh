#!/bin/bash
# @doc
# @name: Configure VS Code settings
# @description: Apply default VS Code settings
# @category: Core
# @usage: bash "Install macOS.command" install-vscode
# @requirements: macOS, VS Code installed
# @notes: Copies default_settings_MacOS.json to the VS Code user settings location
# @/doc

set -euo pipefail

if [[ "${PS_ENV_INITIALIZED:-0}" != "1" ]]; then
  echo "Environment is not initialized. Use Install macOS.command or install_all_macOS.sh." >&2
  exit 2
fi

settings_dir="$HOME/Library/Application Support/Code/User"
settings_file="$settings_dir/settings.json"

echo "=== Applying VS Code Settings ==="
echo ""

if [[ -e "$settings_file" ]]; then
  echo "  [WARNING] $settings_file already exists. Keeping the existing settings."
else
  mkdir -p "$settings_dir"
  if [[ "$PS_ENV" == "offline" ]]; then
    bundled_settings="${PS_BUNDLE_ROOT:?PS_BUNDLE_ROOT is required in offline mode}/Core/VsCode/config/default_settings_MacOS.json"
    [[ -f "$bundled_settings" ]] || {
      echo "  [ERROR] Missing bundled VS Code settings: $bundled_settings" >&2
      exit 1
    }
    cp "$bundled_settings" "$settings_file"
  else
    curl -fsSL "$PS_REPO_URL/Core/VsCode/config/default_settings_MacOS.json" > "$settings_file"
  fi
  echo "  [OK] Settings applied to $settings_file"
fi

echo ""
echo "=== VS Code settings complete! ==="
