#!/usr/bin/env bash

packages_precheck() {
  local pybin="$HOME/miniforge3/bin/python3"
  if [[ ! -x "$pybin" ]]; then
    ui_info "Packages precheck: Miniforge Python not found; packages will be installed when Python is ready."
    return 0
  fi

  local tmpf
  tmpf=$(mktemp)
  cat > "$tmpf" <<'PY'
import importlib, sys
missing = []
for p in sys.argv[1:]:
    try:
        importlib.import_module(p)
    except Exception:
        missing.append(p)
if missing:
    print("MISSING:"+",".join(missing))
    sys.exit(1)
print("OK")
PY
  if "$pybin" "$tmpf" "${DTU_PACKAGES[@]}" >/dev/null 2>&1; then
    ui_info "Required packages already installed. Skipping."
    rm -f "$tmpf"
    return 1
  fi
  rm -f "$tmpf"
  ui_info "Some required packages missing. Will install."
  return 0
}

packages_install() {
  local conda_bin="$HOME/miniforge3/bin/conda"
  [[ -x "$conda_bin" ]] || die "Conda not found; cannot install packages"
  announce "Installing required packages via conda-forge"
  "$conda_bin" install -y -c conda-forge "${DTU_PACKAGES[@]}"
}

