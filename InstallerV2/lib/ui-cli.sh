#!/usr/bin/env bash

ui_info() { echo "$*"; }
ui_warn() { echo "[WARN] $*" >&2; }
ui_error() { echo "[ERROR] $*" >&2; }

ui_confirm() {
  local prompt="$1"
  read -r -p "$prompt [Y/n] " ans
  ans=${ans:-Y}
  [[ "$ans" =~ ^[Yy]$ ]]
}

