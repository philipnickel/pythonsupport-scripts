#!/bin/bash
# Simple consolidated utilities for Python Support Scripts

# === BASIC LOGGING ===
log_info() { echo "[$(date '+%H:%M:%S')] INFO: $1"; }
log_success() { echo "[$(date '+%H:%M:%S')] SUCCESS: $1"; }
log_error() { echo "[$(date '+%H:%M:%S')] ERROR: $1"; }
log_warning() { echo "[$(date '+%H:%M:%S')] WARNING: $1"; }

# === ERROR HANDLING ===
check_exit_code() {
    if [ $? -ne 0 ]; then
        log_error "${1:-Command failed}"
        exit_message
    fi
}

exit_message() {
    echo ""
    echo "Oh no! Something went wrong"
    echo ""
    echo "Please visit: https://pythonsupport.dtu.dk/install/macos/automated-error.html"
    echo "or contact: pythonsupport@dtu.dk"
    echo ""
    exit 1
}

# === LOAD PIWIK ANALYTICS ===
# Load the full piwik utility for analytics
if piwik_script=$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-philipnickel/pythonsupport-scripts}/${BRANCH_PS:-Miniforge}/MacOS/Components/Shared/piwik_utility.sh" 2>/dev/null) && [ -n "$piwik_script" ]; then
    eval "$piwik_script"
else
    # Fallback simple piwik_log if full utility fails to load
    piwik_log() {
        local event_name="$1"
        shift
        local output
        output=$("$@" 2>&1)
        local exit_code=$?
        echo "$output"
        return $exit_code
    }
fi

# === ENVIRONMENT DEFAULTS ===
[ -z "$REMOTE_PS" ] && REMOTE_PS="philipnickel/pythonsupport-scripts"
[ -z "$BRANCH_PS" ] && BRANCH_PS="Miniforge"