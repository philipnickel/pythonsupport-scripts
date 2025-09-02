#!/usr/bin/env bash

packages_precheck() { return 0; }

packages_install() {
  # Prefer dedicated script if it exists; otherwise install via conda/pip
  if [[ -x "MacOS/Components/Python/first_year_setup.sh" ]]; then
    bash "MacOS/Components/Python/first_year_setup.sh"
  else
    # Fallback: install common DTU packages into base env
    if command -v conda >/dev/null 2>&1; then
      conda install -y dtumathtools pandas scipy statsmodels uncertainties || return 1
    elif command -v pip3 >/dev/null 2>&1; then
      pip3 install --user dtumathtools pandas scipy statsmodels uncertainties || return 1
    else
      echo "No conda/pip found to install packages" >&2
      return 1
    fi
  fi
}

packages_verify() {
  python3 - <<'PY'
import importlib, sys
mods = ["dtumathtools","pandas","scipy","statsmodels","uncertainties"]
missing = [m for m in mods if importlib.util.find_spec(m) is None]
sys.exit(1 if missing else 0)
PY
}

