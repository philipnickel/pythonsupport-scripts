#!/usr/bin/env bash

vscode_is_installed() {
  if command -v code >/dev/null 2>&1; then return 0; fi
  if [[ -d "/Applications/Visual Studio Code.app" ]] || [[ -d "$HOME/Applications/Visual Studio Code.app" ]]; then return 0; fi
  return 1
}

_resolve_code_bin() {
  if command -v code >/dev/null 2>&1; then
    command -v code
    return 0
  fi
  if [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
    echo "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    return 0
  fi
  if [[ -x "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
    echo "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    return 0
  fi
  return 1
}

vscode_precheck() {
  if vscode_is_installed; then
    ui_info "VS Code already installed. Skipping."
    return 1
  fi
  ui_info "VS Code not found. Will install."
  return 0
}

vscode_install() {
  announce "Installing Visual Studio Code"
  local target_app="/Applications"
  if [[ ! -w "$target_app" ]]; then
    target_app="$HOME/Applications"
    mkdir -p "$target_app"
  fi

  if command -v brew >/dev/null 2>&1; then
    announce "Using Homebrew to install VS Code"
    brew install --cask visual-studio-code || true
  else
    announce "Downloading VS Code (no Homebrew detected)"
    local url zip tmp
    url="https://update.code.visualstudio.com/latest/darwin/universal/stable"
    tmp=$(mktemp -d)
    zip="$tmp/vscode.zip"
    curl -fsSL "$url" -o "$zip"
    (cd "$tmp" && unzip -q "$zip")
    # Expect "Visual Studio Code.app" folder
    if [[ -d "$tmp/Visual Studio Code.app" ]]; then
      rm -rf "$target_app/Visual Studio Code.app"
      mv "$tmp/Visual Studio Code.app" "$target_app/"
    else
      warn "VS Code archive did not contain expected app bundle"
    fi
    rm -rf "$tmp"
  fi

  # Try to install extensions
  local codebin
  if codebin=$(_resolve_code_bin); then
    for ext in "${VSCODE_EXTENSIONS[@]}"; do
      "$codebin" --install-extension "$ext" || true
    done
    ui_info "Installed VS Code extensions."
  else
    warn "VS Code CLI not found; could not install extensions automatically."
  fi
}

