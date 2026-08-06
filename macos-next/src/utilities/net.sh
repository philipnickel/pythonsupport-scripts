#!/usr/bin/env bash
# Network utility with retry, checksum, cache
set -euo pipefail
IFS=$' \t\n'

NET_CACHE_DIR="${NET_CACHE_DIR:-$HOME/Library/Caches/dtu-python-installer}"
mkdir -p "$NET_CACHE_DIR" 2>/dev/null || true

net::get() {
  local url="$1" dest="$2" tmp
  [[ -z "$url" || -z "$dest" ]] && { echo "net::get: missing args"; return 2; }
  tmp="$dest.part"
  curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 15 --max-time 600 --location --continue-at - -o "$tmp" "$url"
  mv -f "$tmp" "$dest"
}
