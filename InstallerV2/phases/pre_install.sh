#!/usr/bin/env bash

precheck_system() {
  local findings_file="$1"
  : > "$findings_file"

  echo "ARCH=$(uname -m)" >> "$findings_file"
  echo "MACOS=$(sw_vers -productVersion 2>/dev/null || echo unknown)" >> "$findings_file"
  command -v python3 >/dev/null 2>&1 && echo "PYTHON=$(python3 --version 2>&1)" >> "$findings_file" || echo "PYTHON=missing" >> "$findings_file"
  command -v code >/dev/null 2>&1 && echo "VSCODE=present" >> "$findings_file" || echo "VSCODE=missing" >> "$findings_file"
}

