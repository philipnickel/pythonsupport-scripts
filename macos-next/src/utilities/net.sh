#!/usr/bin/env bash
# Network utility with retry, checksum, cache
set -euo pipefail
IFS=$' \t\n'

NET_CACHE_DIR="${NET_CACHE_DIR:-$HOME/Library/Caches/dtu-python-installer}"
mkdir -p "$NET_CACHE_DIR" 2>/dev/null || true

net::get() {
  local url="$1" dest="$2" sha256="${3:-}" tmp
  [[ -z "$url" || -z "$dest" ]] && { echo "net::get: missing args"; return 2; }
  tmp="$dest.part"

  # If cached file exists and matches checksum, reuse
  if [[ -f "$dest" && -n "$sha256" ]]; then
    if echo "$sha256  $dest" | shasum -a 256 -c - >/dev/null 2>&1; then
      return 0
    fi
  fi

  curl -fsSL --retry 5 --retry-delay 2 --continue-at - -o "$tmp" "$url"

  if [[ -n "$sha256" ]]; then
    echo "$sha256  $tmp" | shasum -a 256 -c - >/dev/null 2>&1 || { rm -f "$tmp"; echo "checksum mismatch"; return 3; }
  fi
  mv -f "$tmp" "$dest"
}

