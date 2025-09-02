#!/usr/bin/env bash

detect_arch() {
  uname -m
}

detect_macos_version() {
  sw_vers -productVersion 2>/dev/null || echo "unknown"
}

require_macos() {
  if [[ "$(uname)" != "Darwin" ]]; then
    echo "This installer supports macOS only." >&2
    return 1
  fi
}

miniforge_url_for_arch() {
  local arch
  arch=$(detect_arch)
  if [[ "$arch" == "arm64" ]]; then
    echo "${MINIFORGE_BASE_URL}-arm64.sh"
  else
    echo "${MINIFORGE_BASE_URL}-x86_64.sh"
  fi
}

