#!/usr/bin/env bash
# Miniforge installation (idempotent)
set -euo pipefail
IFS=$' \t\n'

python::miniforge::detect() {
  if [[ -x "${MINIFORGE_PATH}/bin/conda" ]]; then
    echo "present"
  else
    echo "absent"
  fi
}

python::miniforge::install() {
  local arch url sha
  arch=$(uname -m)
  if [[ "$arch" == "arm64" ]]; then
    url="$MINIFORGE_URL_ARM64"; sha="$MINIFORGE_SHA256_ARM64"
  else
    url="$MINIFORGE_URL_X86_64"; sha="$MINIFORGE_SHA256_X86_64"
  fi
  echo "Will install Miniforge to ${MINIFORGE_PATH} from ${url}"
  if [[ "${DRY_RUN:-false}" == true ]]; then return 0; fi
  mkdir -p "$(dirname "$MINIFORGE_PATH")"
  local tmp_installer="/tmp/miniforge_installer.sh"
  net::get "$url" "$tmp_installer"
  bash "$tmp_installer" -b -p "$MINIFORGE_PATH"
}

python::miniforge::verify() {
  if [[ -x "${MINIFORGE_PATH}/bin/conda" ]]; then
    "${MINIFORGE_PATH}/bin/conda" --version || true
    return 0
  fi
  return 1
}
