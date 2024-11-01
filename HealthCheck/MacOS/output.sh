# Requirements arrays remain unchanged

width=60

# Create a colorful banner - unchanged
create_banner() {
    clear
    local text="Welcome to the Python Support Health Check"
    local text_length=${#text}
    local padding=$(( ($width - $text_length - 2) / 2 ))
    local left_padding=$(printf "%*s" $padding)
    local right_padding=$(printf "%*s" $padding)
    local top_bottom_side=$(printf "%*s" $((padding * 2 + 2 + text_length)) | tr ' ' '*')
    local inside_box_width=$(printf "%*s" $((padding * 2 + text_length)))
    echo -e "\x1B[1;34m"
    echo "$top_bottom_side"
    echo "*$inside_box_width*"
    echo -e "*\x1B[1;32m$left_padding$text$right_padding\x1B[1;34m*"
    echo "*$inside_box_width*"
    echo "$top_bottom_side"
    echo -e "\x1B[0m"
}

# Update status function - unchanged
# Update status function - fixed
update_status() {
    local line=$1    # Removed *asterisks*
    local column=$2  # Removed *asterisks*
    local status_string=$3  # Removed *asterisks*
    tput cup $((line+8)) $column
    tput el
    echo $status_string
}

# Install status function - fixed
install_status() {
    local install_status=$1  # Removed *asterisks* and added local
    if [ "$install_status" = "true" ]; then
        status_string="INSTALLED"
        color_code="\x1B[1;42m"
    elif [ "$install_status" = "false" ]; then
        status_string="NOT INSTALLED"
        color_code="\x1B[1;41m"
    else
        status_string="STILL CHECKING"
        color_code="\x1B[1;43m"
    fi
    reset_color="\x1B[0m"
    echo -e "$color_code$status_string$reset_color"
}

# Non-verbose output function remains the same
non_verbose_output() {
    tput civis
    requirements=( "${program_requirements[@]}" "${VSCode_extension_requirements[@]}" "${python_package_requirements[@]}")
    
    # First loop: Display initial status for all requirements
    for i in ${!requirements[@]}; do
        name=$(map_get "healthCheckResults" "${requirements[$i]},name")
        installed=$(map_get "healthCheckResults" "${requirements[$i]},installed")
        status_string=$(install_status "${installed:-}")
        clean_string=$(echo -e "$status_string" | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g')
        
        update_status $i 0 "$name"
        update_status $i $(($width - ${#clean_string})) "$status_string"
    done

    # Second loop: Wait for and update installation status
    for i in ${!requirements[@]}; do
        while true; do
            installed=$(map_get "healthCheckResults" "${requirements[$i]},installed")
            if [[ ! -z "$installed" ]]; then
                break
            fi
            # Sleep for a short period to avoid reading too frequently
            sleep 0.1
        done
        
        status_string=$(install_status "$installed")
        clean_string=$(echo -e "$status_string" | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g')
        update_status $i $(($width - 14)) ""
        update_status $i $(($width - ${#clean_string})) "$status_string"
    done
    
    tput cnorm  # Restore cursor
}

# Function to create a section header
print_section_header() {
    local title=$1
    local width=80  # Wider than non-verbose for more detail
    echo
    echo -e "\x1B[1;34m═══ $title ══$(printf '═%.0s' $(seq $((width - ${#title} - 8))))\x1B[0m"
}

# Function to print a labeled value with optional color
print_info() {
    local label=$1
    local value=$2
    local pad_length=25  # Adjust this for alignment
    printf "\x1B[1;36m%-${pad_length}s\x1B[0m %s\n" "$label:" "$value"
}

# Function to print installation status with color
print_install_status() {
    local status=$1
    if [ "$status" = "true" ]; then
        echo -e "\x1B[1;32mINSTALLED\x1B[0m"
    else
        echo -e "\x1B[1;31mNOT INSTALLED\x1B[0m"
    fi
}

# Func
print_path_status() {
    local status=$1
    if [ "$status" = "true" ]; then
        echo -e "\x1B[1;32mYES\x1B[0m"
    elif [ "$status" = "false" ]; then
        echo -e "\x1B[1;31mNO\x1B[0m"
    fi
}

verbose_output() {
    clear
    create_banner
    
    # System Section
    print_section_header "System Information"
    print_info "CPU Architecture" "$(map_get "healthCheckResults" "sys-info,architecture")"
    print_info "Remaining Disk Space" "$(map_get "healthCheckResults" "sys-info,disk-space")"
    print_info "Rosseta 2 status" "$(print_install_status "$(map_get "healthCheckResults" "sys-info,rosseta2,installed")")"
    
    # Programs Section
    print_section_header "System Programs"
    
    # Python Information
    echo -e "\n\x1B[1;33mPython Information:\x1B[0m"
    print_info "Name" "$(map_get "healthCheckResults" "python3,name")"
    print_info "Installation Status" "$(print_install_status "$(map_get "healthCheckResults" "python3,installed")")"
    print_info "Paths" "$(map_get "healthCheckResults" "python3,paths")"
    print_info "Versions" "$(map_get "healthCheckResults" "python3,versions")"
    
    # Conda Information
    echo -e "\n\x1B[1;33mConda Information:\x1B[0m"
    print_info "Name" "$(map_get "healthCheckResults" "conda,name")"
    print_info "Installation Status" "$(print_install_status "$(map_get "healthCheckResults" "conda,installed")")"
    print_info "Paths" "$(map_get "healthCheckResults" "conda,paths")"
    print_info "Versions" "$(map_get "healthCheckResults" "conda,versions")"
    print_info "Forge Installed" "$(print_path_status "$(map_get "healthCheckResults" "conda,forge_installed")")"
    print_info "Python Path" "$(map_get "healthCheckResults" "conda,python_path")"
    print_info "Python Version" "$(map_get "healthCheckResults" "conda,python_version")"
    
    # VSCode Information
    echo -e "\n\x1B[1;33mVSCode Information:\x1B[0m"
    print_info "Name" "$(map_get "healthCheckResults" "code,name")"
    print_info "Installation Status" "$(print_install_status "$(map_get "healthCheckResults" "code,installed")")"
    print_info "Path" "$(map_get "healthCheckResults" "code,path")"
    print_info "In PATH" "$(print_path_status "$(map_get "healthCheckResults" "code,in-path")")"
    print_info "Version" "$(map_get "healthCheckResults" "code,version")"

    # Homebrew Information
    echo -e "\n\x1B[1;33mHomebrew Information:\x1B[0m"
    print_info "Name" "$(map_get "healthCheckResults" "brew,name")"
    print_info "Installation Status" "$(print_install_status "$(map_get "healthCheckResults" "brew,installed")")"
    print_info "Path" "$(map_get "healthCheckResults" "brew,path")"
    print_info "In PATH" "$(print_path_status "$(map_get "healthCheckResults" "brew,in-path")")"
    print_info "Version" "$(map_get "healthCheckResults" "brew,version")"

    # Extensions Section
    print_section_header "VSCode Extensions"
    
    for ext in "${VSCode_extension_requirements[@]}"; do
        echo -e "\n\x1B[1;33m$(map_get "healthCheckResults" "${ext},name"):\x1B[0m"
        print_info "Installation Status" "$(print_install_status "$(map_get "healthCheckResults" "${ext},installed")")"
        print_info "Version" "$(map_get "healthCheckResults" "${ext},version")"
    done

    # Python Packages Section
    print_section_header "Python Packages"
    
    for package in "${python_package_requirements[@]}"; do
        echo -e "\n\x1B[1;33m$(map_get "healthCheckResults" "${package},name"):\x1B[0m"
        print_info "Installation Status" "$(print_install_status "$(map_get "healthCheckResults" "${package},installed")")"
        print_info "Source" "$(map_get "healthCheckResults" "${package},source")"
        print_info "Path" "$(map_get "healthCheckResults" "${package},path")"
        print_info "Version" "$(map_get "healthCheckResults" "${package},version")"
    done
    
    echo -e "\n\x1B[1;34m$(printf '═%.0s' $(seq 80))\x1B[0m"
}