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
  echo "Conda base: ${MINIFORGE_PATH}"
  "${MINIFORGE_PATH}/bin/conda" info || true
  # Ensure Python via conda in base env
  "${MINIFORGE_PATH}/bin/conda" install -y python="${PYTHON_VERSION_DTU}" || return 1
  # Install conda packages first (fast, with binaries)
  if [[ ${#CONDA_PACKAGES[@]:-0} -gt 0 ]]; then
    "${MINIFORGE_PATH}/bin/conda" install -y "${CONDA_PACKAGES[@]}" || return 1
  fi
  # Then pip packages (DTU-specific)
  if [[ ${#PIP_PACKAGES[@]:-0} -gt 0 ]]; then
    "${MINIFORGE_PATH}/bin/python3" -m pip install --upgrade pip || true
    PIP_NO_INPUT=1 "${MINIFORGE_PATH}/bin/python3" -m pip install "${PIP_PACKAGES[@]}" || return 1
  fi
}

python::base_env::verify() {
  # In CI or dry-run, don't fail verification
  if [[ "${DRY_RUN:-false}" == true ]]; then
    echo "[verify] Skipping package import checks in dry-run"
    return 0
  fi
  if [[ -x "${MINIFORGE_PATH}/bin/python3" ]]; then
    "${MINIFORGE_PATH}/bin/python3" --version || true
    # Basic import test for DTU packages (best effort)
    "${MINIFORGE_PATH}/bin/python3" - <<'PY'
import sys
mods = ["dtumathtools", "pandas", "scipy", "statsmodels", "uncertainties"]
failed = []
for m in mods:
    try:
        __import__(m)
    except Exception as e:
        failed.append((m, str(e)))
if failed:
    print("[verify] Missing/broken modules:")
    for m, err in failed:
        print(f" - {m}: {err}")
    sys.exit(1)
print("[verify] DTU packages import OK")
PY
    return $?
  fi
  echo "[verify] Python not found at ${MINIFORGE_PATH}/bin/python3"
  return 1
}
