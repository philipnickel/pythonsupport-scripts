#!/usr/bin/env bash

# Wrapper calling existing Python component to avoid duplication now.
python_precheck() { return 0; }

python_install() {
  # Reuse current implementation if available
  if [[ -x "MacOS/Components/Python/install.sh" ]]; then
    bash "MacOS/Components/Python/install.sh"
  else
    echo "Python component not found: MacOS/Components/Python/install.sh" >&2
    return 1
  fi
}

python_verify() {
  command -v python3 >/dev/null 2>&1
}

