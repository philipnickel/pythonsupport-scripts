#!/bin/bash

# checks for environmental variables for remote and branch 
if [ -z "$REMOTE_PS" ]; then
  REMOTE_PS="dtudk/pythonsupport-scripts"
fi
if [ -z "$BRANCH_PS" ]; then
  BRANCH_PS="main"
fi

url_ps="https://raw.githubusercontent.com/$REMOTE_PS/$BRANCH_PS/HealthCheck/MacOS"

checkSysInfo_tmp=$(mktemp)
checkPython_tmp=$(mktemp)
checkVsCode_tmp=$(mktemp)
checkBrew_tmp=$(mktemp)
checkFirstYearPackages_tmp=$(mktemp)
map_tmp=$(mktemp)
output_tmp=$(mktemp)

curl -s -o $checkSysInfo_tmp $url_ps/sysInfo_check.sh
curl -s -o $checkPython_tmp $url_ps/check_python.sh
curl -s -o $checkVsCode_tmp $url_ps/check_vsCode.sh
curl -s -o $checkBrew_tmp $url_ps/check_brew.sh
curl -s -o $checkFirstYearPackages_tmp $url_ps/check_firstYearPackages.sh
curl -s -o $map_tmp $url_ps/map.sh
curl -s -o $output_tmp $url_ps/output.sh

source $checkSysInfo_tmp
source $checkPython_tmp
source $checkVsCode_tmp
source $checkBrew_tmp
source $checkFirstYearPackages_tmp
source $map_tmp
source $output_tmp

# Function to clean up resources and exit
cleanup() {
    echo -e "\nCleaning up and exiting..."
    # Kill the non_verbose_output process if it's still running
    if [ ! -z "$output_pid" ]; then
        kill $output_pid 2>/dev/null
    fi

    tput cnorm
    map_cleanup "healthCheckResults"
    release_lock "healthCheckResults"
    
    exit 0
}

# Set up the trap for SIGINT (Ctrl+C)
trap cleanup SIGINT

main() {
    create_banner

    program_requirements=(
    "python3"
    "conda"
    "code"
    "brew"
    )
    VSCode_extension_requirements=(
    "ms-python.python"
    "ms-toolsai.jupyter"
    )
    python_package_requirements=(
    "numpy"
    "dtumathtools"
    "pandas"
    "scipy"
    "statsmodels"
    "uncertainties"
    )
    
    export program_requirements VSCode_extension_requirements python_package_requirements

    # Initialize the health check results map
    map_set "healthCheckResults" "python3,name" "Python"
    map_set "healthCheckResults" "conda,name" "Conda"
    map_set "healthCheckResults" "code,name" "Visual Studio Code"
    map_set "healthCheckResults" "brew,name" "Homebrew"
    map_set "healthCheckResults" "ms-python.python,name" "Python Extension"
    map_set "healthCheckResults" "ms-toolsai.jupyter,name" "Jupyter Extension"
    map_set "healthCheckResults" "numpy,name" "Numpy"
    map_set "healthCheckResults" "dtumathtools,name" "DTU Math Tools"
    map_set "healthCheckResults" "pandas,name" "Pandas"
    map_set "healthCheckResults" "scipy,name" "Scipy"
    map_set "healthCheckResults" "statsmodels,name" "Statsmodels"
    map_set "healthCheckResults" "uncertainties,name" "Uncertainties"
    
    
    non_verbose_output &
    output_pid=$!

    # Run checks sequentially
    check_sysInfo
    check_python
    check_vsCode
    check_brew
    check_firstYearPackages

    if [[ "$1" == "--verbose" || "$1" == "-v" ]]; then
    verbose_output
    fi

    # Wait for the checks to finish being output
    wait

    cleanup
}

# Main execution
main $1