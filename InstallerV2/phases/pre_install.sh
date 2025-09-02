#!/usr/bin/env bash

# Pre-install system checks. Writes summary key=val pairs to a findings file.

precheck_system() {
  local out_file="$1"
  : > "$out_file"

  local arch macos ver_ok
  arch=$(uname -m)
  macos=$(sw_vers -productVersion 2>/dev/null || echo "unknown")

  echo "ARCH=$arch" >> "$out_file"
  echo "MACOS_VERSION=$macos" >> "$out_file"

  # Minimal supported macOS check (10.15+). Keep simple for now.
  if command -v sw_vers >/dev/null 2>&1; then
    IFS='.' read -r major minor patch <<< "${macos}.0"
    if [[ ${major:-0} -gt 10 ]] || [[ ${major:-0} -eq 10 && ${minor:-0} -ge 15 ]]; then
      ver_ok=1
    else
      ver_ok=0
    fi
  else
    ver_ok=1
  fi

  echo "MACOS_SUPPORTED=$ver_ok" >> "$out_file"

  # Free space check (best-effort)
  local freespace
  freespace=$(df -Pk "$HOME" 2>/dev/null | awk 'NR==2 {print $4}')
  echo "FREE_KB_HOME=${freespace:-unknown}" >> "$out_file"

  if [[ "${ver_ok}" != "1" ]]; then
    warn "Detected macOS $macos; versions before 10.15 may not be supported."
  fi

  return 0
}

