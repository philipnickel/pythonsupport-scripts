#!/bin/bash
# Simple utilities for Python Support Scripts

# Set up global log file if not already set
[ -z "$INSTALL_LOG" ] && INSTALL_LOG="/tmp/dtu_install_$(date +%Y%m%d_%H%M%S).log"

# Simple logging that writes to log file and shows in verbose mode
log() { 
    local msg="[$(date '+%H:%M:%S')] $1"
    echo "$msg" >> "$INSTALL_LOG"
    [ "$VERBOSE_MODE" = "true" ] && echo "$msg"
}