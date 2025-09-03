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
  # Enable shell trace in verbose mode (except when building the single-file script)
  if $VERBOSE; then set -x; fi
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
  local -a paths=()
  local candidates=("$HOME/miniforge3" "$HOME/miniconda3" "$HOME/anaconda3" \
                    "/opt/miniforge3" "/opt/miniconda3" "/opt/anaconda3")
  for p in "${candidates[@]}"; do
    if [[ -x "$p/bin/conda" ]]; then paths+=("$p"); fi
  done
  if command -v conda >/dev/null 2>&1; then
    local base; base=$(conda info --base 2>/dev/null || true)
    if [[ -n "${base:-}" && -d "$base" ]]; then paths+=("$base"); fi
  fi
  if ((${#paths[@]})); then
    printf '%s\n' "${paths[@]}" | awk '!seen[$0]++'
  fi
}

# Conda initialization (optional; only when explicitly allowed)
conda::init_shells() {
  if [[ ! -x "${MINIFORGE_PATH:-$HOME/miniforge3}/bin/conda" ]]; then
    log_warn "Conda not found at ${MINIFORGE_PATH:-$HOME/miniforge3}; skipping shell init"
    return 0
  fi
  if [[ "${PIS_ENV:-}" == "CI" ]]; then
    log_info "CI mode: skipping conda init"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "[PLAN] Initialize conda for bash and zsh"
    return 0
  fi
  log_info "Initializing conda for bash and zsh"
  "${MINIFORGE_PATH:-$HOME/miniforge3}/bin/conda" init bash zsh || log_warn "conda init failed"
  log_info "Shells initialized. You may need to restart your terminal."
}

# Post-install summary and hints
summary::print_next_steps() {
  log_info ""
  log_info "Installation Summary"
  log_info "===================="
  log_info "Miniforge: ${MINIFORGE_PATH:-$HOME/miniforge3}"
  if [[ -x "${MINIFORGE_PATH:-$HOME/miniforge3}/bin/python3" ]]; then
    "${MINIFORGE_PATH:-$HOME/miniforge3}/bin/python3" --version || true
  fi
  log_info "VS Code CLI symlink (if installed): $HOME/bin/code"
  log_info "Log file: $DTU_LOG_FILE"
  log_info ""
  log_info "Next steps:"
  log_info " - Close and reopen your terminal (or run: exec \"$SHELL\")"
  log_info " - Ensure \"$HOME/bin\" is in your PATH for 'code' command"
  log_info " - To activate conda in new shells: restart terminal (or run 'conda init bash zsh' manually)"
}

# Precheck: emit simple key=value schema
precheck::run() {
  local env_file="/tmp/macos_next_precheck_$$.env"
  local arch ver conda_list disk_free_gb has_clt min_ok rosetta translated user_shell path_str
  arch=$(os::arch)
  ver=$(os::version)
  conda_list=$(conda::find_all | tr '\n' ',')
  # Disk free in GB (integer)
  disk_free_gb=$(df -g / | awk 'NR==2{print $4}')
  user_shell="$SHELL"
  path_str="$PATH"
  # Command Line Tools
  if /usr/bin/xcode-select -p >/dev/null 2>&1; then has_clt=yes; else has_clt=no; fi
  # Minimal supported macOS (10.15+). Compare major.minor
  min_ok=no
  if [[ "$ver" =~ ^([0-9]+)\.([0-9]+) ]]; then
    local major=${BASH_REMATCH[1]} minor=${BASH_REMATCH[2]}
    if (( major > 10 )) || (( major == 10 && minor >= 15 )); then min_ok=yes; fi
  fi
  # Rosetta/translation detection (best-effort)
  translated=0
  if command -v sysctl >/dev/null 2>&1; then
    translated=$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)
  fi
  if [[ "$arch" == "arm64" && "$translated" == "1" ]]; then rosetta=yes; else rosetta=no; fi

  {
    echo "VERSION=${ver}"
    echo "ARCH=${arch}"
    echo "DISK_FREE_GB=${disk_free_gb}"
    echo "HAS_CLT=${has_clt}"
    echo "MIN_MACOS_OK=${min_ok}"
    echo "UNDER_ROSETTA=${rosetta}"
    echo "CONDA_INSTALLS=${conda_list}"
    echo "SHELL=${user_shell}"
    echo "PATH=${path_str}"
  } | tee "$env_file"

  # Human-readable hints
  [[ "$min_ok" == no ]] && log_warn "Unsupported macOS version: $ver (requires 10.15 or newer)"
  if (( disk_free_gb < 5 )); then log_warn "Low disk space: ${disk_free_gb}G free"; fi
  [[ "$has_clt" == no ]] && log_warn "Xcode Command Line Tools not found; some features may require them"
  [[ "$rosetta" == yes ]] && log_warn "Running under Rosetta; prefer native arm64 tools when possible"

  log_info "Precheck written to $env_file"
}
