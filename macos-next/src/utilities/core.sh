#!/usr/bin/env bash
# Core utilities: logging, args, precheck, runner, UI helpers
set -euo pipefail
IFS=$' \t\n'

# Defaults
: "${PIS_ENV:=}"
: "${DTU_LOG_DIR:=/tmp}"
DTU_LOG_FILE="${DTU_LOG_FILE:-$DTU_LOG_DIR/dtu_macos_next_$(date +%Y%m%d_%H%M%S).log}"

# Logging
log() { printf '%s\n' "$*" | tee -a "$DTU_LOG_FILE"; }
log_info() { log "[INFO] $*"; }
log_warn() { log "[WARN] $*"; }
log_error() { log "[ERROR] $*"; }
die() { log_error "$*"; exit 1; }

# UI adapter (CLI default, GUI via osascript if --gui)
UI_MODE="cli" # or gui
ui::notify() {
  local msg="$1"
  if [[ "$UI_MODE" == "gui" && -x "/usr/bin/osascript" && "${PIS_ENV:-}" != "CI" ]]; then
    /usr/bin/osascript -e "display notification \"${msg}\" with title \"DTU Installer\"" >/dev/null 2>&1 || true
  else
    log_info "$msg"
  fi
}
ui::confirm() {
  local prompt="$1"
  if [[ "$UI_MODE" == "gui" && -x "/usr/bin/osascript" && "${PIS_ENV:-}" != "CI" ]]; then
    /usr/bin/osascript -e "button returned of (display dialog \"${prompt}\" buttons {\"Cancel\", \"OK\"} default button \"OK\")" 2>/dev/null | grep -q "OK"
  else
    read -r -p "$prompt [y/N]: " ans; [[ "$ans" =~ ^[Yy]$ ]]
  fi
}
ui::auth_required() {
  # Placeholder for future GUI auth. For now, just notify.
  ui::notify "Administrator privileges may be required for some steps."
}

# Args
DRY_RUN=false
ASSUME_YES=false
WITH_VSCODE=false
VERBOSE=false
args::parse() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) DRY_RUN=true ; shift;;
      -y|--yes) ASSUME_YES=true ; shift;;
      --with-vscode) WITH_VSCODE=true ; shift;;
      --gui) UI_MODE="gui" ; shift;;
      --no-gui) UI_MODE="cli" ; shift;;
      -v|--verbose) VERBOSE=true ; shift;;
      *) log_warn "Unknown arg: $1"; shift;;
    esac
  done
  # In CI default to dry-run
  if [[ "${PIS_ENV:-}" == "CI" ]]; then DRY_RUN=true; fi
}

# Runner
run_step() {
  local name="$1"; shift || true
  if $DRY_RUN; then
    log_info "[PLAN] $name"
    return 0
  fi
  log_info "[RUN] $name"
  "$@"
}

# OS / arch helpers
os::arch() { uname -m; }
os::version() { sw_vers -productVersion 2>/dev/null || echo "unknown"; }

# Conda detection (lightweight)
conda::find_all() {
  local paths=()
  local candidates=("$HOME/miniforge3" "$HOME/miniconda3" "$HOME/anaconda3" \
                    "/opt/miniforge3" "/opt/miniconda3" "/opt/anaconda3")
  for p in "${candidates[@]}"; do
    if [[ -x "$p/bin/conda" ]]; then paths+=("$p"); fi
  done
  if command -v conda >/dev/null 2>&1; then
    local base; base=$(conda info --base 2>/dev/null || true)
    if [[ -n "${base:-}" && -d "$base" ]]; then paths+=("$base"); fi
  fi
  printf '%s\n' "${paths[@]}" | awk '!seen[$0]++'
}

# Precheck: emit simple key=value schema
precheck::run() {
  local env_file="/tmp/macos_next_precheck_$$.env"
  local arch ver conda_list disk_free
  arch=$(os::arch)
  ver=$(os::version)
  conda_list=$(conda::find_all | tr '\n' ',')
  disk_free=$(df -H / | awk 'NR==2{print $4}')
  {
    echo "VERSION=${ver}"
    echo "ARCH=${arch}"
    echo "DISK_FREE=${disk_free}"
    echo "CONDA_INSTALLS=${conda_list}"
  } | tee "$env_file"
  log_info "Precheck written to $env_file"
}

