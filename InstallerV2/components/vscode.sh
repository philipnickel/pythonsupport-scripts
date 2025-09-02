#!/usr/bin/env bash

vscode_precheck() { return 0; }

vscode_install() {
  if [[ -x "MacOS/Components/VSC/install.sh" ]]; then
    bash "MacOS/Components/VSC/install.sh"
  else
    echo "VS Code component not found: MacOS/Components/VSC/install.sh" >&2
    return 1
  fi
}

vscode_verify() {
  command -v code >/dev/null 2>&1
}

