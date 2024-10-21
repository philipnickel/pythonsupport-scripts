#!/bin/bash

# Source the key-value store library
#source /path/to/kv_store.sh  # Make sure to update this path

code_path=$(which code 2>/dev/null)
code_extensions=("ms-python.python" "ms-toolsai.jupyter")

check_vsCode() {
    # Check VSCode itself
    if [ -d "$code_path" ]; then
        map_set "healthCheckResults" "code,installed" "false"
    else
        map_set "healthCheckResults" "code,installed" "true"
    fi
    
    map_set "healthCheckResults" "code,path" "$code_path"
    
    # Get version and store it
    version=$($code_path --version 2>/dev/null | head -n 1)
    map_set "healthCheckResults" "code,version" "$version"
    
    # Check each extension
    for extension in "${code_extensions[@]}"; do
        # Get extension version
        version=$(code --list-extensions --show-versions 2>/dev/null | grep "${extension}" | cut -d "@" -f 2)
        
        # Set installed status
        if [ -z "$version" ]; then
            map_set "healthCheckResults" "${extension},installed" "false"
        else
            map_set "healthCheckResults" "${extension},installed" "true"
        fi
        
        # Set version
        map_set "healthCheckResults" "${extension},version" "$version"
    done
}