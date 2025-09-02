#!/usr/bin/env bash

python_is_installed() {
  [[ -x "$HOME/miniforge3/bin/python3" ]]
}

python_precheck() {
  if python_is_installed; then
    ui_info "Python (Miniforge) already installed. Skipping."
    return 1
  fi
  ui_info "Python (Miniforge) not found. Will install."
  return 0
}

python_install() {
  local url installer prefix
  url="$(miniforge_url_for_arch)"
  installer="/tmp/miniforge-installer.sh"
  prefix="$HOME/miniforge3"

  announce "Downloading Miniforge: $url"
  curl -fsSL "$url" -o "$installer"

  announce "Installing Miniforge to $prefix"
  bash "$installer" -b -p "$prefix"

  local conda_bin
  conda_bin="$prefix/bin/conda"
  [[ -x "$conda_bin" ]] || die "Conda not found after Miniforge install"

  announce "Configuring conda channels"
  "$conda_bin" config --set channel_priority strict || true
  "$conda_bin" config --remove channels defaults || true
  "$conda_bin" config --add channels conda-forge || true

  announce "Ensuring Python ${DTU_PYTHON_VERSION}"
  "$conda_bin" install -y "python=${DTU_PYTHON_VERSION}"

  ui_info "Miniforge installed at $prefix"
}

