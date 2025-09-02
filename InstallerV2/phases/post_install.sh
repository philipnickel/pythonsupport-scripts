#!/usr/bin/env bash

# Post-install verification. Returns 0 on full success, 1 if issues.

post_verify() {
  local findings_file="$1"
  local ok=1

  # Verify Python (Miniforge)
  local pybin
  pybin="$HOME/miniforge3/bin/python3"
  if [[ -x "$pybin" ]]; then
    log "Python found at $pybin: $($pybin --version 2>/dev/null | tr -d '\n')"
  else
    warn "Miniforge Python not found at $pybin"
    ok=0
  fi

  # Verify packages
  if [[ -x "$pybin" ]]; then
    local test_script
    test_script=$(cat <<'PY'
import importlib, sys
pkgs = "    ,".join(sys.argv[1:])
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
)
    local tmpf
    tmpf=$(mktemp)
    echo "$test_script" > "$tmpf"
    if "$pybin" "$tmpf" "${DTU_PACKAGES[@]}" >/dev/null 2>&1; then
      log "Required Python packages import successfully"
    else
      warn "Some required Python packages failed to import"
      ok=0
    fi
    rm -f "$tmpf"
  fi

  # Verify VS Code and extensions
  local codebin
  if command -v code >/dev/null 2>&1; then
    codebin="$(command -v code)"
  elif [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
    codebin="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  elif [[ -x "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
    codebin="$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  else
    codebin=""
  fi

  if [[ -n "$codebin" ]]; then
    if "$codebin" --list-extensions 2>/dev/null | grep -q "ms-python.python"; then
      log "VS Code present and Python extension installed"
    else
      warn "VS Code present but Python extension missing"
      ok=0
    fi
  else
    warn "VS Code not found"
    ok=0
  fi

  if [[ $ok -eq 1 ]]; then return 0; else return 1; fi
}

