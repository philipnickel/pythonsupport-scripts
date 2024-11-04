#!/bin/bash

check_sysInfo() {
    # Check system architecture
    map_set "healthCheckResults" "sys-info,architecture" "$(uname -m 2>/dev/null)"

    # Check disk space
    map_set "healthCheckResults" "sys-info,disk-space" "$(df -h / | tail -1 | awk '{print $4}' 2>/dev/null)"

    # Check Rosseta 2 installation
    if [[ "$(sysctl -n machdep.cpu.brand_string)" == *'Apple'* ]]; then
        if arch -x86_64 /usr/bin/true 2>/dev/null; then
            result=true
        else
            result=false
        fi
    fi
    map_set "healthCheckResults" "sys-info,rosseta2,installed" "$result"
}
