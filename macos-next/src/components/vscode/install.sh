#!/usr/bin/env bash
# VS Code installation (optional)
set -euo pipefail
IFS=$' \t\n'

vscode::install() {
  echo "Install VS Code from pinned URL"
  if [[ "${DRY_RUN:-false}" == true ]]; then return 0; fi
  local zip="/tmp/VSCode.zip"
  net::get "$VSCODE_URL_UNIVERSAL" "$zip"
  unzip -qq -o "$zip" -d /tmp/
  local target_app
  target_app="$HOME/Applications/Visual Studio Code.app"
  mkdir -p "$HOME/Applications"
  rm -rf "$target_app"
  mv "/tmp/Visual Studio Code.app" "$target_app"
  xattr -d com.apple.quarantine "$target_app" 2>/dev/null || true
  mkdir -p "$HOME/bin" && ln -sf "$target_app/Contents/Resources/app/bin/code" "$HOME/bin/code"
}

vscode::verify() {
  if [[ -x "$HOME/bin/code" ]]; then "$HOME/bin/code" --version || true; fi
}
