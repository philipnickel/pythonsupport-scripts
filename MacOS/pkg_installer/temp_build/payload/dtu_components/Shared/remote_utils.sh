#!/bin/bash
# @doc
# @name: Remote Script Utilities
# @description: Functions for safely downloading and sourcing remote scripts and files
# @category: Utilities
# @usage: source remote_utils.sh
# @requirements: curl, internet connection
# @notes: Provides secure remote script execution and file downloading capabilities
# @/doc

# Function to source a remote script safely
source_remote_script() {
    local script_url="$1"
    local script_name="${2:-remote script}"
    
    log_info "Sourcing remote script: $script_name"
    local script_content
    if script_content=$(curl -fsSL "$script_url" 2>/dev/null) && [ -n "$script_content" ]; then
        eval "$script_content"
        log_success "Successfully sourced $script_name"
    else
        log_error "Failed to source remote script: $script_name"
        log_error "URL: $script_url"
        exit_message
    fi
}

# Function to download a file safely
download_file() {
    local url="$1"
    local destination="$2"
    local description="${3:-file}"
    
    log_info "Downloading $description..."
    if curl -fsSL "$url" -o "$destination"; then
        log_success "Downloaded $description to $destination"
    else
        log_error "Failed to download $description from $url"
        exit_message
    fi
}

# Function to check if a URL is accessible
check_url() {
    local url="$1"
    local timeout="${2:-10}"
    
    if curl -fsSL --max-time "$timeout" --head "$url" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to get latest GitHub release information
get_github_latest_release() {
    local repo="$1"
    local api_url="https://api.github.com/repos/$repo/releases/latest"
    
    if check_url "$api_url"; then
        curl -fsSL "$api_url" | grep '"tag_name":' | cut -d '"' -f 4
    else
        log_error "Failed to fetch latest release for $repo"
        return 1
    fi
}

# Function to get the correct GitHub raw URL
get_github_raw_url() {
    local repo="$1"
    local branch="${2:-main}"
    local path="$3"
    
    echo "https://raw.githubusercontent.com/$repo/$branch/$path"
}

# Function to source multiple utility scripts
source_utils() {
    local utils=("$@")
    local base_url=$(get_base_url)
    
    for util in "${utils[@]}"; do
        local util_url="$base_url/Components/Shared/$util.sh"
        source_remote_script "$util_url" "$util utilities"
    done
}

# Function to execute a remote script with arguments
execute_remote_script() {
    local script_url="$1"
    shift
    local args=("$@")
    
    log_info "Executing remote script: $script_url"
    if bash -c "$(curl -fsSL "$script_url")" -- "${args[@]}"; then
        log_success "Remote script executed successfully"
    else
        log_error "Remote script execution failed"
        exit_message
    fi
}

# Function to validate script integrity (basic check)
validate_script_content() {
    local content="$1"
    
    # Basic validation - check for common script indicators
    if echo "$content" | grep -q "#!/bin/bash\|#!/bin/sh"; then
        return 0
    else
        log_warning "Script content validation failed - no proper shebang found"
        return 1
    fi
}