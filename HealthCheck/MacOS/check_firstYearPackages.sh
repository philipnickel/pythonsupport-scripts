#!/bin/bash

eval "$(conda shell.bash hook)" 2>/dev/null
conda_eviroment="base"  
conda activate -n $conda_eviroment 2>/dev/null
conda_python_path=$(which python3 2>/dev/null)
conda deactivate 2>/dev/null

python_path=$(which python3 2>/dev/null)


python_packages=("numpy" "dtumathtools" "pandas" "scipy" "statsmodels" "uncertainties")

declare -A firstYearPackages_check

check_package_installed() {
    local package=$1
    
    $conda_python_path -c "import $package" 2>/dev/null || 
    $python_path -c "import $package" 2>/dev/null
}

check_package_source() {
    local package=$1

    conda_list_output=$(conda list -n $conda_eviroment | grep $package | head -n 1)
    conda_list_package_source=$(echo $conda_list_output | cut -d " " -f 4)
    pip_list_output=$($python_path -m pip list | grep $package | head -n 1)
    
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
    source /tmp/healthCheckResults

    for package in "${python_packages[@]}"; do
        healthCheckResults[$package,installed]=$(check_package_installed "$package" && echo true || echo false)
        healthCheckResults[$package,source]=$(check_package_source "$package")

        conda_path=$($conda_python_path -c "import $package; print($package.__file__)" 2>/dev/null)
        system_path=$($python_path -c "import $package; print($package.__file__)" 2>/dev/null)
        package_path=($conda_path $system_path)
        healthCheckResults[$package,path]="${package_path[*]}"
        
        conda_version=$($conda_python_path -c "import $package; print($package.__version__)" 2>/dev/null)
        system_version=$($python_path -c "import $package; print($package.__version__)" 2>/dev/null)
        package_version=($conda_version $system_version)
        healthCheckResults[$package,version]="${package_version[*]}"

        save_healthCheckResults
    done

    
}