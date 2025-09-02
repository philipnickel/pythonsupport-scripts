#!/usr/bin/env bash

ui_info() {
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$*\" with title \"DTU Installer\"" >/dev/null 2>&1 || true
  else
    echo "$*"
  fi
}

ui_warn() {
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display alert \"Warning\" message \"$*\"" >/dev/null 2>&1 || true
  else
    echo "[WARN] $*" >&2
  fi
}

ui_error() {
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display alert \"Error\" message \"$*\" as critical" >/dev/null 2>&1 || true
  else
    echo "[ERROR] $*" >&2
  fi
}

ui_confirm() {
  local prompt="$1"
  if command -v osascript >/dev/null 2>&1; then
    local result
    result=$(osascript -e "display dialog \"$prompt\" buttons {\"No\",\"Yes\"} default button 2" 2>/dev/null || true)
    echo "$result" | grep -q "button returned:Yes"
  else
    read -r -p "$prompt [Y/n] " ans
    ans=${ans:-Y}
    [[ "$ans" =~ ^[Yy]$ ]]
  fi
}

