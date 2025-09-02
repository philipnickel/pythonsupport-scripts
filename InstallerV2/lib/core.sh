#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -z "${EMBEDDED:-}" ]]; then
  source "$ROOT_DIR/lib/logging.sh"
  source "$ROOT_DIR/lib/config.sh"
  source "$ROOT_DIR/lib/platform.sh"
  source "$ROOT_DIR/lib/telemetry.sh"
fi

# UI switching is controlled from bin/install.sh; here we just rely on funcs

FINDINGS_FILE=${FINDINGS_FILE:-"/tmp/dtu_pre_install_findings.env"}

if [[ -z "${EMBEDDED:-}" ]]; then
  source "$ROOT_DIR/phases/pre_install.sh"
  source "$ROOT_DIR/phases/post_install.sh"

  source "$ROOT_DIR/components/python.sh"
  source "$ROOT_DIR/components/vscode.sh"
  source "$ROOT_DIR/components/packages.sh"
fi

parse_args() {
  UI_MODE_AUTO=1
  DRY_RUN=0
  NO_ANALYTICS=0
  INSTALL_PREFIX_OVERRIDE=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --cli) UI_MODE="cli"; UI_MODE_AUTO=0; shift ;;
      --gui) UI_MODE="gui"; UI_MODE_AUTO=0; shift ;;
      --dry-run) DRY_RUN=1; shift ;;
      --no-analytics) NO_ANALYTICS=1; shift ;;
      --prefix=*) INSTALL_PREFIX_OVERRIDE="${1#*=}"; shift ;;
      *) echo "Unknown flag: $1"; exit 2 ;;
    esac
  done

  if [[ -n "$INSTALL_PREFIX_OVERRIDE" ]]; then
    INSTALL_PREFIX="$INSTALL_PREFIX_OVERRIDE"
  fi

  if [[ "$NO_ANALYTICS" == "1" ]]; then
    DTU_ANALYTICS_ENABLED=0
  fi
}

auto_select_ui() {
  if [[ -n "${UI_MODE:-}" ]]; then return; fi
  if [[ -n "${DTU_UI:-}" ]]; then UI_MODE="$DTU_UI"; return; fi
  if [[ -t 1 ]] && command -v osascript >/dev/null 2>&1; then
    UI_MODE="gui"
  else
    UI_MODE="cli"
  fi
}

run_phase_pre() {
  announce "Pre-checking system"
  precheck_system "$FINDINGS_FILE"
}

run_phase_install() {
  announce "Installing components"
  if python_precheck; then
    [[ "$DRY_RUN" -eq 1 ]] || python_install
  fi
  if vscode_precheck; then
    [[ "$DRY_RUN" -eq 1 ]] || vscode_install
  fi
  if packages_precheck; then
    [[ "$DRY_RUN" -eq 1 ]] || packages_install
  fi
}

run_phase_post() {
  announce "Verifying installation"
  post_verify "$FINDINGS_FILE"
}

main_core() {
  require_macos || die "macOS required"
  parse_args "$@"
  auto_select_ui

  # shellcheck disable=SC1090
  if [[ -z "${EMBEDDED:-}" ]]; then
    if [[ "$UI_MODE" == "gui" ]]; then
      source "$ROOT_DIR/lib/ui-gui.sh"
    else
      source "$ROOT_DIR/lib/ui-cli.sh"
    fi
  fi

  log "Installer start: UI=$UI_MODE arch=$(detect_arch) macOS=$(detect_macos_version)"

  if [[ "$DTU_ANALYTICS_ENABLED" == "1" ]]; then
    CONSENT=$(telemetry_consent)
    [[ "$CONSENT" == "yes" ]] || DTU_ANALYTICS_ENABLED=0
  fi

  ui_info "DTU Installer starting (UI: $UI_MODE)"
  run_phase_pre
  run_phase_install
  if run_phase_post; then
    ui_info "Installation verified successfully."
    log "Install OK"
  else
    ui_warn "Installation completed with issues. See log: $LOG_FILE"
    log "Install issues detected"
  fi
}
