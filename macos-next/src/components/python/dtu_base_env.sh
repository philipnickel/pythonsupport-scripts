#!/usr/bin/env bash
# Ensure DTU base Python env and packages
set -euo pipefail
IFS=$' \t\n'

python::base_env::ensure() {
  echo "Ensure Python ${PYTHON_VERSION_DTU} and DTU packages in base env"
  if [[ "${DRY_RUN:-false}" == true ]]; then return 0; fi
  if [[ ! -x "${MINIFORGE_PATH}/bin/conda" ]]; then
    echo "Conda not found at ${MINIFORGE_PATH}; abort"; return 1
  fi
  "${MINIFORGE_PATH}/bin/conda" install -y python="${PYTHON_VERSION_DTU}" || return 1
  "${MINIFORGE_PATH}/bin/conda" install -y "${DTU_PACKAGES[@]}" || return 1
}

python::base_env::verify() {
  if [[ -x "${MINIFORGE_PATH}/bin/python3" ]]; then
    "${MINIFORGE_PATH}/bin/python3" --version || true
    return 0
  fi
  return 1
}

