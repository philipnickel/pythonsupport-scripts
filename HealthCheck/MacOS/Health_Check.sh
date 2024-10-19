#!/bin/bash

# Template for how to source the scripts from github
#source <(curl -s https://raw.githubusercontent.com/user/repo/branch/path/to/script.sh)


script_full_path=$(dirname "$0")
source "$script_full_path/output.sh"
source "$script_full_path/check_python.sh"
source "$script_full_path/check_vsCode.sh"
source "$script_full_path/check_firstYearPackages.sh"

# Function to clean up resources and exit
cleanup() {
    echo -e "\nCleaning up and exiting..."
    running=false
    # Kill the non_verbose_output process if it's still running
    if [ ! -z "$output_pid" ]; then
        kill $output_pid 2>/dev/null
    fi

    tput cnorm
    rm /tmp/healthCheckResults

    exit 1
}

save_healthCheckResults() {
    declare -p healthCheckResults > /tmp/healthCheckResults
}

export -f save_healthCheckResults

# Set up the trap for SIGINT (Ctrl+C)
trap cleanup SIGINT

main() {
    create_banner

    declare -A healthCheckResults
    healthCheckResults=(
        ["python3,name"]="Python"
        ["conda,name"]="Conda"
        ["code,name"]="Visual Studio Code"
        ["ms-python.python,name"]="Python Extension"
        ["ms-toolsai.jupyter,name"]="Jupyter Extension"
        ["numpy,name"]="Numpy"
        ["dtumathtools,name"]="DTU Math Tools"
        ["pandas,name"]="Pandas"
        ["scipy,name"]="Scipy"
        ["statsmodels,name"]="Statsmodels"
        ["uncertainties,name"]="Uncertainties"
    )
    save_healthCheckResults

    

    # Start non_verbose_output in background
    non_verbose_output &
    output_pid=$!

    # Run checks sequentially
    check_python
    check_vsCode
    check_firstYearPackages

    # Wait for the checks to finish being output
    wait

    cleanup
}

# Main execution
if [[ "$1" == "--verbose" || "$1" == "-v" ]]; then
    ## NEED TO REIMPLEMENT THIS ##
    verbose_output
else
    main
fi