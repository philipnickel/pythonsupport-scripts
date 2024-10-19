#!/bin/bash

code_path=$(which code 2>/dev/null)
code_extensions=("ms-python.python" "ms-toolsai.jupyter")

declare -A vscode_check

check_vsCode() {
    source /tmp/healthCheckResults

    healthCheckResults[code,installed]="$([ -d "$code_path" ] && echo false || echo true)"
    healthCheckResults[code,path]=$code_path
    healthCheckResults[code,version]=$($code_path --version 2>/dev/null | head -n 1)

    save_healthCheckResults

    for index in "${!code_extensions[@]}"; do
        healthCheckResults[${code_extensions[$index]},version]=$(code --list-extensions --show-versions 2>/dev/null | grep "${code_extensions[$index]}" | cut -d "@" -f 2)
        healthCheckResults[${code_extensions[$index]},installed]="$([ ${#vscode_check[code,extension,${code_extensions[$index]},version]} -eq 0 ] && echo false || echo true)"
        save_healthCheckResults
    done

    
}