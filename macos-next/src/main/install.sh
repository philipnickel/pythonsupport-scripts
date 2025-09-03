#!/usr/bin/env bash
set -euo pipefail
IFS=$' \t\n'

# Source modules (functions only)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$ROOT_DIR/src/utilities/core.sh"
source "$ROOT_DIR/src/utilities/net.sh"
source "$ROOT_DIR/src/etc/config.sh"
source "$ROOT_DIR/src/components/python/miniforge.sh"
source "$ROOT_DIR/src/components/python/dtu_base_env.sh"
source "$ROOT_DIR/src/components/vscode/install.sh"

main() {
  args::parse "$@"
  ui::notify "DTU macOS Installer (next) starting"

  log_info "Mode: $([[ "$UI_MODE" == gui ]] && echo GUI || echo CLI) | Dry-run: $DRY_RUN | With VS Code: $WITH_VSCODE"

  # Plan preview
  log_info "Execution plan:"
  log_info " - Precheck system"
  log_info " - Ensure Miniforge"
  log_info " - Ensure Python ${PYTHON_VERSION_DTU} and DTU packages"
  $WITH_VSCODE && log_info " - Install VS Code" || log_info " - VS Code skipped"

  # In dry-run, only render plan and precheck
  precheck::run
  if $DRY_RUN; then
    log_info "Dry-run complete. No changes made."
    exit 0
  fi

  # Steps
  if [[ "$(python::miniforge::detect)" == "absent" ]]; then
    run_step "Install Miniforge" python::miniforge::install
  else
    log_info "Miniforge already present at ${MINIFORGE_PATH}"
  fi

  run_step "Ensure DTU base Python env" python::base_env::ensure
  run_step "Verify DTU base Python env" python::base_env::verify

  if $WITH_VSCODE; then
    run_step "Install VS Code" vscode::install
    run_step "Verify VS Code" vscode::verify
  fi

  log_info "Installation completed. Log: $DTU_LOG_FILE"
}

main "$@"
