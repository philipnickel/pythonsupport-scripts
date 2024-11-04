#!/bin/bash

# Common paths
brew_path=$(which brew 2>/dev/null)
python_common_dirs=(
    "/usr/local/bin"
    "/usr/bin"
    "/opt/homebrew/bin"
    "$HOME/.local/bin"
)
conda_common_dirs=(
    "$HOME/miniconda3/bin"
    "$HOME/anaconda3/bin"
    "/opt/miniconda3/bin"
    "/opt/anaconda3/bin"
    "/usr/local/anaconda3/bin"
    "/usr/local/miniconda3/bin"
    "/usr/local/Caskroom/miniconda/base/bin"
    "/usr/local/bin"
)

sys_architecture=$(uname -m)

check_command_exists() {
    local cmd=$1
    # Check if command exists using various methods
    command -v "$cmd" >/dev/null 2>&1 || \
    hash "$cmd" 2>/dev/null || \
    type -P "$cmd" >/dev/null 2>&1
    return $?
}

check_python() {
    local python_found=false
    local conda_found=false
    local python_paths=()
    local python_versions=()
    local conda_paths=()
    local conda_versions=()
    
    # Check Python installation
    # 1. Check common Python paths
    for dir in "${python_common_dirs[@]}"; do
        if [ -x "$dir/python3" ]; then
            python_found=true
            python_paths+=("$dir/python3")
            version=$("$dir/python3" --version 2>/dev/null | cut -d' ' -f2)
            if [ -n "$version" ]; then
                python_versions+=("$version")
            fi
        fi
    done

    # 2. Check Python in PATH
    if check_command_exists python3; then
        python_found=true
        path=$(which python3 2>/dev/null)
        if [[ ! " ${python_paths[*]} " =~ " ${path} " ]]; then
            python_paths+=("$path")
            version=$(python3 --version 2>/dev/null | cut -d' ' -f2)
            if [ -n "$version" ]; then
                python_versions+=("$version")
            fi
        fi
    fi

    # Check Conda installation
    # 1. Check common Conda directories
    for dir in "${conda_common_dirs[@]}"; do
        if [ -d "$dir" ] && [ -x "$dir/conda" ]; then
            conda_found=true
            conda_paths+=("$dir")
            version=$($dir --version 2>/dev/null | cut -d' ' -f2)
            if [ -n "$version" ]; then
                conda_versions+=("$version")
            fi
        fi
    done

    # 2. Check Conda in PATH
    if check_command_exists conda; then
        conda_found=true
        path=$(dirname "$(which conda)" 2>/dev/null)
        if [[ ! " ${conda_paths[*]} " =~ " ${path} " ]]; then
            conda_paths+=("$path")
            version=$(conda --version 2>/dev/null | cut -d' ' -f2)
            if [ -n "$version" ]; then
                conda_versions+=("$version")
            fi
        fi
    fi

    # Check Conda Python
    local conda_python_path=""
    local conda_python_version=""
    if $conda_found; then
        eval "$(conda shell.bash hook)" 2>/dev/null
        conda activate base 2>/dev/null
        if check_command_exists python3; then
            conda_python_path=$(which python3 2>/dev/null)
            conda_python_version=$("$conda_python_path" --version 2>/dev/null | cut -d' ' -f2)
        fi
        conda deactivate 2>/dev/null
    fi

    # Verify installations by attempting to run
    if $python_found; then
        python3 -c "print('test')" >/dev/null 2>&1 || python_found=false
    fi
    if $conda_found; then
        conda info >/dev/null 2>&1 || conda_found=false
        conda_forge_installed=$([ $(conda config --show channels | grep -c "conda-forge") -gt 0 ] && echo "true" || echo "false")
    fi


    # Store results
    map_set "healthCheckResults" "python3,installed" "$python_found"
    map_set "healthCheckResults" "python3,paths" "${python_paths[*]}"
    map_set "healthCheckResults" "python3,versions" "${python_versions[*]}"
    
    map_set "healthCheckResults" "conda,installed" "$conda_found"
    map_set "healthCheckResults" "conda,paths" "${conda_paths[*]}"
    map_set "healthCheckResults" "conda,versions" "${conda_versions[*]}"
    map_set "healthCheckResults" "conda,forge_installed" "$conda_forge_installed"
    
    map_set "healthCheckResults" "conda,python_path" "$conda_python_path"
    map_set "healthCheckResults" "conda,python_version" "$conda_python_version"
}