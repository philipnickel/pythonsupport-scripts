#!/bin/bash

brew_path=$(which brew 2>/dev/null) 
user_python_dir="usr/local/bin"
conda_dir=("$HOME/miniconda3/" "$HOME/anaconda3/" "/opt/miniconda3/" "/opt/anaconda3/")
brew_conda_path="$brew_path/miniconda/"

check_python() {
    user_python_path=$(ls $python_path 2>/dev/null | grep "python")

    conda_path=()
    for path in "${conda_dir[@]}"; do
        if [ -d $path ]; then
            conda_python+=("$path")
        fi
    done


    if [ -d "$brew_conda" ]; then
        conda_python+=("$brew_conda")
    fi

    default_conda=$(which conda 2>/dev/null)
    default_conda_version=$(conda --version 2>/dev/null | cut -d " " -f 2)

    eval "$(conda shell.bash hook)" 2>/dev/null
    conda activate 2>/dev/null
    default_conda_python=$(which python3)
    conda deactivate 2>/dev/null
    default_conda_python_version=$($default_conda_python --version 2>/dev/null | cut -d " " -f 2)

    default_python=$(which python3)
    default_python_version=$($default_python --version 2>/dev/null | cut -d " " -f 2)
    

    source /tmp/healthCheckResults

    healthCheckResults["python3,installed"]="$([ ${#user_python[@]} -eq 0 ] && echo false || echo true)"
    healthCheckResults["python3,path"]="$python_path"
    healthCheckResults["python3,version"]="$default_python_version"

    healthCheckResults["conda,installed"]="$([ ${#conda_python[@]} -eq 0 ] && echo false || echo true)"
    healthCheckResults["conda,version"]=$default_conda_version
    healthCheckResults["conda,path"]="$default_conda"
    healthCheckResults["conda,python_version"]="$default_conda_python_version"
    healthCheckResults["conda,python_path"]="$default_conda_python"

    save_healthCheckResults
}