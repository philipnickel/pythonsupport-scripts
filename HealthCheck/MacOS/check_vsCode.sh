#!/bin/bash

# Source the key-value store library
#source /path/to/kv_store.sh  # Make sure to update this path
code_common_dirs=(
    "/usr/local/bin"
)

check_vsCode() {

    # Check VSCode itself
    for dir in "${code_common_dirs[@]}"; do
        if [ -x "$dir" ]; then
            code_path=$dir/code
            map_set "healthCheckResults" "code,installed" "true"
            break
        else
            map_set "healthCheckResults" "code,installed" "false"
        fi
    done
    
    map_set "healthCheckResults" "code,path" "$code_path"
    
    # Check if VSCode is in PATH
    if echo $PATH | grep -q $(dirname $code_path) ; then
        map_set "healthCheckResults" "code,in-path" "true"
    else
        map_set "healthCheckResults" "code,in-path" "false"
    fi

    # Get version and store it
    version=$($code_path --version 2>/dev/null | head -n 1)
    map_set "healthCheckResults" "code,version" "$version"
    
    # Check each extension
    for extension in "${VSCode_extension_requirements[@]}"; do
        # Get extension version
        version=$($code_path --list-extensions --show-versions 2>/dev/null | grep "${extension}" | cut -d "@" -f 2)
        
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