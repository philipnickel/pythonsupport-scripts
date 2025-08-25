#!/bin/bash
# Simple consolidated utilities for Python Support Scripts

# === CENTRALIZED LOGGING SYSTEM ===
# Set up global log file if not already set
[ -z "$INSTALL_LOG" ] && INSTALL_LOG="/tmp/dtu_install_$(date +%Y%m%d_%H%M%S).log"

# Logging functions that write to both log file and stdout (if in verbose mode)
log_info() { 
    local msg="[$(date '+%H:%M:%S')] INFO: $1"
    echo "$msg" >> "$INSTALL_LOG"
    [ "$VERBOSE_MODE" = "true" ] && echo "$msg"
}
log_success() { 
    local msg="[$(date '+%H:%M:%S')] SUCCESS: $1"
    echo "$msg" >> "$INSTALL_LOG"
    [ "$VERBOSE_MODE" = "true" ] && echo "$msg"
}
log_error() { 
    local msg="[$(date '+%H:%M:%S')] ERROR: $1"
    echo "$msg" >> "$INSTALL_LOG"
    [ "$VERBOSE_MODE" = "true" ] && echo "$msg"
}
log_warning() { 
    local msg="[$(date '+%H:%M:%S')] WARNING: $1"
    echo "$msg" >> "$INSTALL_LOG"
    [ "$VERBOSE_MODE" = "true" ] && echo "$msg"
}

# === ERROR HANDLING ===
check_exit_code() {
    if [ $? -ne 0 ]; then
        log_error "${1:-Command failed}"
        exit 1
    fi
}


# === CENTRALIZED PIWIK ANALYTICS ===
# Enhanced piwik_log that pipes all output to log file
piwik_log() {
    local event_name="$1"
    shift
    
    log_info "Starting: $event_name"
    
    local output
    local exit_code
    
    # Execute command and capture all output to log file
    if [ "$QUIET_MODE" = "true" ]; then
        # In quiet mode, show progress spinner
        printf "Processing $event_name... "
        
        # Run command in background
        ("$@") >> "$INSTALL_LOG" 2>&1 &
        local cmd_pid=$!
        
        # Simple spinner animation
        local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
        local i=0
        while kill -0 $cmd_pid 2>/dev/null; do
            printf "\rProcessing $event_name... ${chars:$i:1}"
            i=$(((i + 1) % ${#chars}))
            sleep 0.1
        done
        
        # Get exit code and show result
        wait $cmd_pid
        exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            printf "\r✓ $event_name completed\n"
        else
            printf "\r✗ $event_name failed\n"
        fi
    else
        # In verbose mode, show output normally
        output=$("$@" 2>&1)
        exit_code=$?
        echo "$output" | tee -a "$INSTALL_LOG"
    fi
    
    log_info "Completed: $event_name (exit code: $exit_code)"
    return $exit_code
}