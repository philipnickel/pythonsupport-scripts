#!/bin/bash
# Minimal utilities for Python Support Scripts

# Set up global log file if not already set
[ -z "$INSTALL_LOG" ] && INSTALL_LOG="/tmp/dtu_install_$(date +%Y%m%d_%H%M%S).log"