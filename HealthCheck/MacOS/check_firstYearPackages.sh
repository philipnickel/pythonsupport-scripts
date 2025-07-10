#!/bin/bash

# Initialize conda
eval "$(conda shell.bash hook)"
# Set the conda environment
conda_eviroment="base"  
conda activate -n $conda_eviroment 2>/dev/null
conda_python_path=$(which python 2>/dev/null)
conda deactivate 2>/dev/null

python_path=$(which python3 2>/dev/null)


check_package_installed() {
    local package=$1
   
    $conda_python_path -c "import $package" 2>/dev/null ||
    $python_path -c "import $package" 2>/dev/null
}

check_package_source() {
    local package=$1
    conda_list_output=$(conda list -n $conda_eviroment 2>/dev/null | grep $package | head -n 1)
    conda_list_package_source=$(echo $conda_list_output | cut -d " " -f 4)
    pip_list_output=$($python_path -m pip list 2>/dev/null | grep $package | head -n 1)
   
    package_source=()
    if [ -n "$conda_list_package_source" ]; then
        package_source+=($conda_list_package_source)
    elif [ -n "$conda_list_output" ]; then
        package_source+=("conda")
    fi
    if [ -n "$pip_list_output" ]; then
        package_source+=("pip")
    fi
    echo ${package_source[*]}
}

check_package_info() {
    local package=$1
    local python_cmd=$2
    local info_type=$3
    echo $($python_cmd -c "import $package; print($package.__$info_type__)" 2>/dev/null)
}

check_firstYearPackages() {
    for package in "${python_package_requirements[@]}"; do
        # Check if package is installed
        if check_package_installed "$package"; then
            map_set "healthCheckResults" "${package},installed" "true"
        else
            map_set "healthCheckResults" "${package},installed" "false"
        fi

        # Get and store package source
        source_info=$(check_package_source "$package")
        map_set "healthCheckResults" "${package},source" "$source_info"

        # Get and store package paths
        conda_path=$($conda_python_path -c "import $package; print($package.__file__)" 2>/dev/null)
        system_path=$($python_path -c "import $package; print($package.__file__)" 2>/dev/null)
        package_path=($conda_path $system_path)
        map_set "healthCheckResults" "${package},path" "${package_path[*]}"
       
        # Get and store package versions
        conda_version=$($conda_python_path -c "import $package; print($package.__version__)" 2>/dev/null)
        system_version=$($python_path -c "import $package; print($package.__version__)" 2>/dev/null)
        package_version=($conda_version $system_version)
        map_set "healthCheckResults" "${package},version" "${package_version[*]}"
    done
}