#!/usr/bin/env bash
set -o pipefail

LOG_FILE=${LOG_FILE:-"/tmp/dtu_install_$(date +%Y%m%d_%H%M%S).log"}

ts() { date '+%Y-%m-%d %H:%M:%S'; }

log_raw() {
  echo "[$(ts)] $*" | tee -a "$LOG_FILE"
}

log() { log_raw "INFO: $*"; }
warn() { log_raw "WARN: $*" >&2; }
error() { log_raw "ERROR: $*" >&2; }

die() {
  error "$*"
  exit 1
}

announce() {
  echo "==> $*" | tee -a "$LOG_FILE"
}

