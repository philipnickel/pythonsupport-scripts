#!/bin/bash

program_requirements=(
    "python3"
    "conda"
    "code"
)
extension_requirements=(
    "ms-python.python"
    "ms-toolsai.jupyter"
)
package_requirements=(
    "numpy"
    "dtumathtools"
    "pandas"
    "scipy"
    "statsmodels"
    "uncertainties"
)

width=60


# Create a colorful banner
create_banner() {
    clear
    local text="Welcome to the Python Support Health Check"
    local text_length=${#text}
    local padding=$(( ($width - $text_length - 2) / 2 ))

    local left_padding=$(printf "%*s" $padding)
    local right_padding=$(printf "%*s" $padding)
    local top_bottom_side=$(printf "%*s" $((padding * 2 + 2 + text_length)) | tr ' ' '*')
    local inside_box_width=$(printf "%*s" $((padding * 2 + text_length)))

    echo -e "\e[1;34m"
    echo "$top_bottom_side"
    echo "*$inside_box_width*"
    echo -e "*\e[1;32m$left_padding$text$right_padding\e[1;34m*"
    echo "*$inside_box_width*"
    echo "$top_bottom_side"
    echo -e "\e[0m"
}

# Function to update the status
update_status() {
    local line=$1
    local column=$2
    local status=$3

    # Move cursor to the correct position and clear the line
    tput cup $((line+8)) $column
    tput el
    echo $status
}

install_status() {
    install_status=$1

    if [ "$install_status" = "true" ]; then
        status="INSTALLED"
        color_code="\e[1;42m"  # White text on green background
    elif [ "$install_status" = "false" ]; then
        status="NOT INSTALLED"
        color_code="\e[1;41m"  # White text on red background
    else
        status="STILL CHECKING"
        color_code="\e[1;43m"  # White text on yellow background
    fi

    reset_color="\e[0m"  # Reset to default color

    echo -e "${color_code}${status}${reset_color}"
}

non_verbose_output() {
    tput civis
    requirements=( "${program_requirements[@]}" "${extension_requirements[@]}" "${package_requirements[@]}")
    
    for i in ${!requirements[@]}; do
        name=${healthCheckResults["${requirements[$i]},name"]}
        status=$(install_status "${healthCheckResults["${requirements[$i]},installed"]}")
        clean_string=$(echo -e "$status" | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g')

        update_status $i 0 "$name"
        update_status $i $(($width - ${#clean_string})) "$status"
    done

    for i in ${!requirements[@]}; do
        while true; do
            source /tmp/healthCheckResults
            if [[ ! -z "${healthCheckResults["${requirements[$i]},installed"]}" ]]; then
                break
            fi
            # Sleep for a short period to avoid sources being read too quickly
            sleep 0.1
        done

        status=$(install_status "${healthCheckResults["${requirements[$i]},installed"]}")
        clean_string=$(echo -e "$status" | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g')

        update_status $i $(($width - 14)) ""
        update_status $i $(($width - ${#clean_string})) "$status"
    done

}


###########################################
# NEED TO REIMPLEMENT THIS
###########################################

# Verbose output function
verbose_output() {
    echo "Health Check Detailed Summary:"
    printf '%*s\n' "$display_width" '' | tr ' ' '='

    declare -A health_check_results
    health_check_results = $1

    # First year programs
    for program in "${required_programs[@]}"; do
        program_results="${health_check_results[$program,installed]}"
        program_name="${health_check_results[$program,name]}"
        program_version="${health_check_results[$program,version]}"
        program_path="${health_check_results[$program,path]}"

        if [ "$program_results" = true ]; then
            status="INSTALLED"
            color_code="\e[1;42m"  # White text on green background
        elif [ "$program_results" = false ]; then
            status="NOT INSTALLED"
            color_code="\e[1;41m"  # White text on red background
        else
            status="STILL CHECKING"
            color_code="\e[1;43m"  # White text on yellow background
        fi

        reset_color="\e[0m"  # Reset to default color
        echo -e "${program_name}: ${color_code}${status}${reset_color}"
        echo "Version: $program_version"
        echo "Path: $program_path"
    done

    # First year extensions
    for extension in "ms-python.python" "ms-toolsai.jupyter"; do
        extension_results="${health_check_results[code,extensions,$extension,installed]}"
        extension_name="${health_check_results[code,extensions,$extension,name]}"
        extension_version="${health_check_results[code,extensions,$extension,version]}"

        if [ "$extension_results" = true ]; then
            status="INSTALLED"
            color_code="\e[1;42m"  # White text on green background
        elif [ "$extension_results" = false ]; then
            status="NOT INSTALLED"
            color_code="\e[1;41m"  # White text on red background
        else
            status="STILL CHECKING"
            color_code="\e[1;43m"  # White text on yellow background
        fi

        reset_color="\e[0m"  # Reset to default color
        echo -e "${extension_name}: ${color_code}${status}${reset_color}"
        echo "Version: $extension_version"
    done

    # First year packages
    for package in "${required_packages[@]}"; do
        package_results="${health_check_results[firstYearPackages,$package,installed]}"
        package_name="${health_check_results[firstYearPackages,$package,name]}"
        package_version="${health_check_results[firstYearPackages,$package,version]}"
        package_path="${health_check_results[firstYearPackages,$package,path]}"
        package_source="${health_check_results[firstYearPackages,$package,source]}"

        if [ "$package_results" = true ]; then
            status="INSTALLED"
            color_code="\e[1;42m"  # White text on green background
        elif [ "$package_results" = false ]; then
            status="NOT INSTALLED"
            color_code="\e[1;41m"  # White text on red background
        else
            status="STILL CHECKING"
            color_code="\e[1;43m"  # White text on yellow background
        fi

        reset_color="\e[0m"  # Reset to default color
        echo -e "${package_name}: ${color_code}${status}${reset_color}"
        echo "Version: $package_version"
        echo "Source: $package_source"
        echo "Path: $package_path"
    done
}