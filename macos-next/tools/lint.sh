#!/usr/bin/env bash
set -euo pipefail
IFS=$' \t\n'

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck not found; attempting to install (Linux)"
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y && sudo apt-get install -y shellcheck
  else
    echo "Please install shellcheck manually"; exit 1
  fi
fi

echo "Running shellcheck on sources"
shellcheck -x macos-next/src/**/*.sh || true

