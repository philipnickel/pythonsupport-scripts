#!/bin/bash
# ====================================================================
# DTU Python Diagnostics Report Generator - Enhanced with Profiles & Templates
# ====================================================================
# Auto-discovers and organizes diagnostic components by profile configuration
# and uses template system for HTML generation
#
# SCRIPT STRUCTURE:
# Section 1: Initialization & Configuration - Setup, config loading, variables, argument parsing
# Section 2: Utility Functions - Helper functions for metadata, timeouts, etc.
# Section 3: Component Discovery & Diagnostic Execution - Find and run tests from profiles
# Section 4: HTML Report Generation - Create interactive HTML report using templates
# Section 5: Finalization & Cleanup - Summary, browser opening, cleanup
#
# MAINTAINABILITY NOTES:
# - Each section has a clear purpose and can be modified independently
# - HTML generation uses external templates for easier customization
# - Configuration is externalized to report_config.sh
# - Components are loaded from profile configuration files
# - All temporary files are automatically cleaned up
# ====================================================================

# ====================================================================
# COMMAND-LINE ARGUMENT PARSING
# ====================================================================

# Default profile
SELECTED_PROFILE="comprehensive"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --profile)
            SELECTED_PROFILE="$2"
            shift 2
            ;;
        --profile=*)
            SELECTED_PROFILE="${1#*=}"
            shift
            ;;
        -h|--help)
            echo "DTU Python Diagnostics Report Generator"
            echo "Usage: $0 [options] [output_file]"
            echo ""
            echo "Options:"
            echo "  --profile <name>     Use specific diagnostic profile (default: comprehensive)"
            echo "  -h, --help          Show this help message"
            echo ""
            echo "Available profiles:"
            if [[ -d "$(dirname "${BASH_SOURCE[0]}")/profiles" ]]; then
                for profile_file in "$(dirname "${BASH_SOURCE[0]}")/profiles"/*.conf; do
                    if [[ -f "$profile_file" ]]; then
                        profile_name=$(basename "$profile_file" .conf)
                        echo "  - $profile_name"
                    fi
                done
            fi
            exit 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
        *)
            # This is the output file argument
            break
            ;;
    esac
done

# Don't exit on errors - we want report to generate even with failures
set +e

# ====================================================================
# SECTION 1: INITIALIZATION & CONFIGURATION
# ====================================================================

# Create secure temporary directory for logs
TEMP_DIR=$(mktemp -d -t "dtu_diagnostics")
trap "rm -rf '$TEMP_DIR'" EXIT INT TERM

# Output locations - include profile name in filename
if [[ "$SELECTED_PROFILE" != "comprehensive" ]]; then
    REPORT_FILE="${1:-$HOME/Desktop/DTU_Python_Diagnostics_${SELECTED_PROFILE}_$(date +%Y%m%d_%H%M%S).html}"
else
    REPORT_FILE="${1:-$HOME/Desktop/DTU_Python_Diagnostics_$(date +%Y%m%d_%H%M%S).html}"
fi
LOG_DIR="$TEMP_DIR/logs"
mkdir -p "$LOG_DIR"

# Color codes for terminal output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "DTU Python Diagnostics Report Generator"
echo "Selected profile: $SELECTED_PROFILE"
echo "Temporary directory: $TEMP_DIR"
echo "Report will be saved to: $REPORT_FILE"
echo ""

# Enhanced System Information Section
echo -e "${BLUE}═══════════════════════════════════════"
echo "SYSTEM INFORMATION"
echo "═══════════════════════════════════════${NC}"

# macOS Version Information
echo -e "${GREEN}macOS Information:${NC}"
echo "  Product Name: $(sw_vers -productName 2>/dev/null || echo 'Unknown')"
echo "  Version: $(sw_vers -productVersion 2>/dev/null || echo 'Unknown')"
echo "  Build: $(sw_vers -buildVersion 2>/dev/null || echo 'Unknown')"
echo ""

# Hardware Information
echo -e "${GREEN}Hardware Information:${NC}"
echo "  Architecture: $(uname -m 2>/dev/null || echo 'Unknown')"
echo "  Hostname: $(hostname 2>/dev/null || echo 'Unknown')"
echo "  Kernel: $(uname -sr 2>/dev/null || echo 'Unknown')"
if command -v system_profiler >/dev/null 2>&1; then
    # Get CPU info (with timeout to prevent hanging)
    cpu_info=$(timeout 3 system_profiler SPHardwareDataType 2>/dev/null | grep "Processor Name" | cut -d':' -f2 | sed 's/^ *//' || echo 'Unknown')
    memory_info=$(timeout 3 system_profiler SPHardwareDataType 2>/dev/null | grep "Memory" | cut -d':' -f2 | sed 's/^ *//' || echo 'Unknown')
    echo "  Processor: $cpu_info"
    echo "  Memory: $memory_info"
fi
echo ""

# User Environment
echo -e "${GREEN}User Environment:${NC}"
echo "  Username: $(whoami 2>/dev/null || echo 'Unknown')"
echo "  Home Directory: $HOME"
echo "  Current Shell: $SHELL"
echo "  PATH Entries: $(echo $PATH | tr ':' '\n' | wc -l | tr -d ' ') directories"
echo ""

# Development Tools Check
echo -e "${GREEN}Development Tools Overview:${NC}"
# Check for common development tools with version info
for tool in python python3 pip pip3 conda brew code git; do
    if command -v "$tool" >/dev/null 2>&1; then
        tool_path=$(which "$tool" 2>/dev/null)
        case "$tool" in
            python|python3)
                version=$($tool --version 2>/dev/null | head -1)
                ;;
            pip|pip3)
                version=$($tool --version 2>/dev/null | head -1 | awk '{print $2}')
                version="version $version"
                ;;
            conda)
                version=$($tool --version 2>/dev/null | head -1)
                version="version $(echo "$version" | awk '{print $2}')"
                ;;
            brew)
                version="version $($tool --version 2>/dev/null | head -1 | awk '{print $2}')"
                ;;
            code)
                version=$($tool --version 2>/dev/null | head -1)
                version="version $version"
                ;;
            git)
                version=$($tool --version 2>/dev/null | awk '{print $3}')
                version="version $version"
                ;;
        esac
        echo "  ✓ $tool: $version ($tool_path)"
    else
        echo "  ✗ $tool: Not found"
    fi
done
echo ""

# Environment Variables of Interest
echo -e "${GREEN}Python Environment Variables:${NC}"
for var in PYTHONPATH VIRTUAL_ENV CONDA_DEFAULT_ENV PYTHONHOME; do
    if [[ -n "${!var}" ]]; then
        echo "  $var: ${!var}"
    else
        echo "  $var: (not set)"
    fi
done
echo ""

echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

# Default repository coordinates (can be overridden via env/config)
REPO_OWNER=${REPO_OWNER:-philipnickel}
REPO_NAME=${REPO_NAME:-pythonsupport-scripts}
# Prefer main by default; fall back handled by helper when fetching
REPO_BRANCH=${REPO_BRANCH:-main}

# ====================================================================
# SECTION 2: UTILITY FUNCTIONS
# ====================================================================

# Function to extract metadata from diagnostic script
extract_metadata() {
    local script_path="$1"
    local field="$2"
    
    if [[ -f "$script_path" ]]; then
        grep "^# @$field:" "$script_path" 2>/dev/null | head -1 | cut -d':' -f2- | sed 's/^ *//'
    fi
}

# Download a file from the repository, trying fallback branches if needed
# Usage: download_repo_file "MacOS/Components/Diagnostics/<path>" "/dest/file"
download_repo_file() {
    local repo_path="$1"
    local dest_path="$2"

    # Branch preference order: configured branch -> main -> macos-components (deduplicated)
    local -a branches=()
    [[ -n "$REPO_BRANCH" ]] && branches+=("$REPO_BRANCH")
    [[ "$REPO_BRANCH" != "main" ]] && branches+=("main")
    [[ "$REPO_BRANCH" != "macos-components" && "main" != "macos-components" ]] && branches+=("macos-components")

    for br in "${branches[@]}"; do
        local url="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${br}/${repo_path}"
        if curl -sfL "$url" -o "$dest_path" && [[ -s "$dest_path" ]]; then
            echo "$br" > "/dev/null" # keep for potential future debugging
            return 0
        fi
    done
    return 1
}

# Function to load diagnostic components from profile configuration
discover_components() {
    echo -e "${BLUE}Loading diagnostic components for profile: $SELECTED_PROFILE${NC}" >&2
    
    local profile_file
    local profile_loaded=false
    
    # Determine script directory
    if [[ "${BASH_SOURCE[0]}" == "/dev/stdin" ]] || [[ "${BASH_SOURCE[0]}" == "bash" ]]; then
        # Running remotely via curl - download profile from repository
        echo "Downloading profile configuration from repository..." >&2
        profile_file="$TEMP_DIR/${SELECTED_PROFILE}.conf"
        if download_repo_file "MacOS/Components/Diagnostics/profiles/${SELECTED_PROFILE}.conf" "$profile_file"; then
            source "$profile_file"
            profile_loaded=true
            echo "  Profile loaded from repository: $SELECTED_PROFILE" >&2
        fi
    else
        # Running locally
        local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        profile_file="$SCRIPT_DIR/profiles/${SELECTED_PROFILE}.conf"
        if [[ -f "$profile_file" ]]; then
            source "$profile_file"
            profile_loaded=true
            echo "  Profile loaded from local file: $profile_file" >&2
        fi
    fi
    
    # Fallback to comprehensive profile if selected profile not found
    if [[ "$profile_loaded" != "true" ]]; then
        echo -e "${YELLOW}Warning: Profile '$SELECTED_PROFILE' not found. Falling back to comprehensive profile.${NC}" >&2
        SELECTED_PROFILE="comprehensive"
        
        if [[ "${BASH_SOURCE[0]}" == "/dev/stdin" ]] || [[ "${BASH_SOURCE[0]}" == "bash" ]]; then
            profile_file="$TEMP_DIR/comprehensive.conf"
            if download_repo_file "MacOS/Components/Diagnostics/profiles/comprehensive.conf" "$profile_file"; then
                source "$profile_file"
                profile_loaded=true
            fi
        else
            local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            profile_file="$SCRIPT_DIR/profiles/comprehensive.conf"
            if [[ -f "$profile_file" ]]; then
                source "$profile_file"
                profile_loaded=true
            fi
        fi
    fi
    
    # Ultimate fallback to hardcoded comprehensive components if no profile found
    if [[ "$profile_loaded" != "true" ]]; then
        echo -e "${YELLOW}Warning: No profile configuration found. Using hardcoded comprehensive components.${NC}" >&2
        PROFILE_NAME="Comprehensive Environment (Fallback)"
        PROFILE_DESCRIPTION="Complete diagnostic suite - all available Python, conda, development tools, and system checks (fallback mode)"
        COMPONENTS=(
            "Python:Installation:python_installation_check:Python Installation Check:Components/Python/Installation/python_installation_check.sh"
            "Python:Environment:python_environment:Python Environment Configuration:Components/Python/Environment/python_environment.sh"
            "Python:Packages:first_year_packages:First Year Required Packages:Components/Python/Packages/first_year_packages.sh"
            "Conda:Installation:conda_installation:Conda Installation Check:Components/Conda/Installation/conda_installation.sh"
            "Conda:Environments:conda_environments:Conda Environments Check:Components/Conda/Environments/conda_environments.sh"
            "Development:Homebrew:homebrew_installation:Homebrew Installation Check:Components/Development/Homebrew/homebrew_installation.sh"
            "System Information:Information:system_info:System Information:Components/System Information/Information/system_info.sh"
            "Visual Studio Code:Installation:vscode_installation:VS Code Installation Check:Components/Visual Studio Code/Installation/vscode_installation.sh"
            "Visual Studio Code:Extensions:python_extensions:Python Development Extensions:Components/Visual Studio Code/Extensions/python_extensions.sh"
        )
    fi
    
    # Validate that COMPONENTS array is set
    if [[ -z "${COMPONENTS:-}" ]] || [[ "${#COMPONENTS[@]}" -eq 0 ]]; then
        echo -e "${RED}Error: No components defined in profile configuration${NC}" >&2
        exit 1
    fi
    
    # Output component definitions for sourcing
    echo "DISCOVERED_CATEGORIES=("
    for component in "${COMPONENTS[@]}"; do
        echo "  \"$component\""
    done
    echo ")"
    
    # Set global profile variables for template processing
    echo "PROFILE_NAME='${PROFILE_NAME:-$SELECTED_PROFILE}'"
    echo "PROFILE_DESCRIPTION='${PROFILE_DESCRIPTION:-Diagnostic profile: $SELECTED_PROFILE}'"
    
    # Count components
    local count=${#COMPONENTS[@]}
    echo "  Loaded $count diagnostic components from profile: $SELECTED_PROFILE" >&2
    echo "" >&2
}

# Load configuration file
# Handle both local execution and remote execution via curl
if [[ "${BASH_SOURCE[0]}" == "/dev/stdin" ]] || [[ "${BASH_SOURCE[0]}" == "bash" ]]; then
    # Running remotely via curl, download config file using branch fallbacks
    echo "Loading configuration from repository..."
    CONFIG_FILE="$TEMP_DIR/report_config.sh"
    if download_repo_file "MacOS/Components/Diagnostics/report_config.sh" "$CONFIG_FILE"; then
        source "$CONFIG_FILE"
        echo "Configuration loaded from repository"
    else
        echo "Warning: Could not load configuration from repository (branches tried: $REPO_BRANCH, main, macos-components). Using defaults."
    fi
else
    # Running locally
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CONFIG_FILE="$SCRIPT_DIR/report_config.sh"
    if [[ -f "$CONFIG_FILE" ]]; then
        echo "Loading configuration from: $CONFIG_FILE"
        source "$CONFIG_FILE"
    fi
fi

# Configuration (use config file values if available, otherwise fallbacks)
PARALLEL_ENABLED=${PARALLEL_ENABLED:-true}
MAX_PARALLEL=${MAX_PARALLEL_JOBS:-${MAX_PARALLEL:-5}}
DEFAULT_TIMEOUT=${DEFAULT_GLOBAL_TIMEOUT:-${DEFAULT_TIMEOUT:-20}}

# Bash-based timeout function when timeout command isn't available
bash_timeout() {
    local timeout=$1
    shift
    
    # Start the command in background
    "$@" &
    local pid=$!
    
    # Start a timer subprocess
    ( sleep "$timeout" && kill -TERM "$pid" 2>/dev/null && sleep 1 && kill -KILL "$pid" 2>/dev/null ) &
    local timer_pid=$!
    
    # Wait for the command to finish
    wait "$pid" 2>/dev/null
    local exit_code=$?
    
    # Kill the timer if still running
    kill -TERM "$timer_pid" 2>/dev/null
    wait "$timer_pid" 2>/dev/null
    
    # Check if process was killed by timeout (143 = SIGTERM, 137 = SIGKILL)
    if [[ $exit_code -eq 143 || $exit_code -eq 137 ]]; then
        return 124  # Return standard timeout exit code
    fi
    
    return $exit_code
}

# Run diagnostic component and capture result
run_diagnostic() {
    local main_category="$1"
    local subcategory="$2"
    local script_name="$3"
    local display_name="$4"
    local script_path="$5"
    local category_key="${main_category}_${subcategory//\//_}"
    local log_file="$LOG_DIR/${category_key}_${script_name%.sh}.log"
    local status_file="$TEMP_DIR/status_${category_key}_${script_name%.sh}"
    local exit_code=0
    local start_time=$(date +%s)
    
    echo -e "\n${BLUE}Running:${NC} $main_category > $subcategory → $display_name"
    echo "  Script: $script_path"
    echo "  Timeout: ${timeout:-$DEFAULT_TIMEOUT}s"
    echo -n "  Status: "
    
    # Download script from repository with branch fallbacks
    local temp_script="$TEMP_DIR/${script_name}.sh"
    if ! download_repo_file "MacOS/Components/Diagnostics/$script_path" "$temp_script"; then
        echo -e "${RED}✗ Script download failed${NC}"
        echo "ERROR: Failed to download script from any known branch for path: MacOS/Components/Diagnostics/$script_path" > "$log_file"
        echo "2" > "$status_file"
        return 2
    fi
    
    # Extract timeout from script metadata or use default (handles empty metadata)
    local timeout
    timeout=$(extract_metadata "$temp_script" "timeout")
    timeout=${timeout:-$DEFAULT_TIMEOUT}
    
    # Run diagnostic with timeout and capture output
    # Use gtimeout if available (macOS with coreutils), otherwise timeout, otherwise no timeout
    if command -v gtimeout >/dev/null 2>&1; then
        timeout_cmd="gtimeout"
    elif command -v timeout >/dev/null 2>&1; then
        timeout_cmd="timeout"
    else
        timeout_cmd=""
    fi
    
    if [[ -n "$timeout_cmd" ]]; then
        if $timeout_cmd "$timeout" bash "$temp_script" > "$log_file" 2>&1; then
            exit_code=0
            echo -e "${GREEN}✓ PASSED${NC}"
        else
            exit_code=$?
            if [[ $exit_code -eq 124 ]]; then
                echo -e "${YELLOW}⚠ TIMEOUT after ${timeout}s${NC}"
                echo "ERROR: Script timed out after ${timeout}s" >> "$log_file"
                echo "" >> "$log_file"
            else
                echo -e "${RED}✗ FAILED with exit code $exit_code${NC}"
            fi
        fi
    else
        # Use bash-based timeout as fallback
        if bash_timeout "$timeout" bash "$temp_script" > "$log_file" 2>&1; then
            exit_code=0
            echo -e "${GREEN}✓ PASSED${NC}"
        else
            exit_code=$?
            if [[ $exit_code -eq 124 ]]; then
                echo -e "${YELLOW}⚠ TIMEOUT after ${timeout}s${NC}"
                echo "ERROR: Script timed out after ${timeout}s" >> "$log_file"
                echo "" >> "$log_file"
            else
                echo -e "${RED}✗ FAILED with exit code $exit_code${NC}"
            fi
        fi
    fi
    
    # Calculate execution time
    local end_time=$(date +%s)
    local exec_time=$((end_time - start_time))
    echo "  Execution time: ${exec_time}s"
    echo "EXEC_TIME:${exec_time}" >> "$log_file"
    
    # Save status for parallel processing
    echo "$exit_code" > "$status_file"
    
    return $exit_code
}

# Run diagnostic in background for parallel execution
run_diagnostic_parallel() {
    local main_category="$1"
    local subcategory="$2" 
    local script_name="$3"
    local display_name="$4"
    local script_path="$5"
    local category_key="${main_category}_${subcategory//\//_}"
    local log_file="$LOG_DIR/${category_key}_${script_name%.sh}.log"
    local status_file="$TEMP_DIR/status_${category_key}_${script_name%.sh}"
    local start_time=$(date +%s)
    
    # Load configuration for background process
    # Check if config was already loaded from repository (passed via environment)
    if [[ -z "$DEFAULT_GLOBAL_TIMEOUT" ]]; then
        # Try to load local config if available
        local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        local CONFIG_FILE="$SCRIPT_DIR/report_config.sh"
        if [[ -f "$CONFIG_FILE" ]]; then
            source "$CONFIG_FILE"
        fi
    fi
    
    {
        # Download script from repository
        local temp_script="$TEMP_DIR/${script_name}.sh"
        if ! download_repo_file "MacOS/Components/Diagnostics/$script_path" "$temp_script"; then
            echo "ERROR: Failed to download script from any known branch for path: MacOS/Components/Diagnostics/$script_path" > "$log_file"
            echo "2" > "$status_file"
            exit 2
        fi
        
        # Extract timeout from script metadata or use default (handles empty metadata)
        local timeout
        timeout=$(extract_metadata "$temp_script" "timeout")
        timeout=${timeout:-$DEFAULT_TIMEOUT}
        
        # Determine timeout command
        if command -v gtimeout >/dev/null 2>&1; then
            timeout_cmd="gtimeout"
        elif command -v timeout >/dev/null 2>&1; then
            timeout_cmd="timeout"
        else
            timeout_cmd=""
        fi
        
        # Run diagnostic with timeout and capture output
        if [[ -n "$timeout_cmd" ]]; then
            if $timeout_cmd "$timeout" bash "$temp_script" > "$log_file" 2>&1; then
                echo "0" > "$status_file"
            else
                exit_code=$?
                if [[ $exit_code -eq 124 ]]; then
                    echo "ERROR: Script timed out after ${timeout}s" >> "$log_file"
                    echo "" >> "$log_file"
                fi
                echo "$exit_code" > "$status_file"
            fi
        else
            # Use bash-based timeout as fallback
            if bash_timeout "$timeout" bash "$temp_script" > "$log_file" 2>&1; then
                echo "0" > "$status_file"
            else
                exit_code=$?
                if [[ $exit_code -eq 124 ]]; then
                    echo "ERROR: Script timed out after ${timeout}s" >> "$log_file"
                    echo "" >> "$log_file"
                fi
                echo "$exit_code" > "$status_file"
            fi
        fi
        
        # Calculate execution time
        local end_time=$(date +%s)
        local exec_time=$((end_time - start_time))
        echo "EXEC_TIME:${exec_time}" >> "$log_file"
    } &
}

# Function to generate report with embedded fallback template
generate_fallback_report() {
    echo "Generating report with embedded fallback template..."
    {
cat > "$REPORT_FILE" << 'HTML_TEMPLATE'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DTU Python Diagnostics Report</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: Arial, sans-serif; /* DTU fallback font */
            line-height: 1.6;
            color: #000000; /* DTU Black */
            background: #DADADA; /* DTU Grey background */
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: #ffffff; /* DTU White */
            border-radius: 8px;
            box-shadow: 0 4px 16px rgba(0,0,0,0.1);
            overflow: hidden;
            display: flex;
            flex-direction: column;
            min-height: 80vh;
        }
        
        
        .download-section {
            display: flex;
            justify-content: center;
            gap: 15px;
            padding: 15px 20px;
            background: #f8f9fa;
            border-bottom: 1px solid #dee2e6;
        }
        
        .download-button {
            padding: 12px 24px;
            border: 2px solid #990000; /* DTU Corporate Red */
            background: #ffffff; /* DTU White */
            color: #990000; /* DTU Corporate Red */
            border-radius: 4px;
            cursor: pointer;
            font-weight: 600;
            font-family: Arial, sans-serif;
            transition: all 0.3s;
            font-size: 1em;
        }
        
        .download-button:hover {
            background: #990000; /* DTU Corporate Red */
            color: #ffffff; /* DTU White */
        }
        
        header {
            background: #990000; /* DTU Corporate Red */
            color: #ffffff; /* DTU White */
            padding: 40px 30px;
            text-align: center;
            position: relative;
        }
        
        
        .dtu-logo {
            position: absolute;
            top: 20px;
            left: 30px;
            height: 50px;
            width: auto;
            filter: brightness(0) invert(1); /* Make logo white on red background */
        }
        
        @media (max-width: 768px) {
            .dtu-logo {
                position: static;
                display: block;
                margin: 0 auto 20px;
                height: 40px;
            }
            
            .header-actions {
                position: static;
                justify-content: center;
                margin-bottom: 20px;
            }
            
            .action-button {
                font-size: 0.8em;
                padding: 6px 12px;
            }
        }
        
        h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .timestamp {
            opacity: 0.9;
            font-size: 0.9em;
        }
        
        .summary {
            display: flex;
            justify-content: center;
            gap: 40px;
            padding: 30px;
            background: #f8f9fa;
            border-bottom: 1px solid #dee2e6;
        }
        
        .summary-item {
            text-align: center;
        }
        
        .summary-number {
            font-size: 3em;
            font-weight: bold;
        }
        
        .summary-label {
            color: #6c757d;
            text-transform: uppercase;
            font-size: 0.8em;
            letter-spacing: 1px;
        }
        
        .passed { color: #008835; } /* DTU Green */
        .failed { color: #E83F48; } /* DTU Red */
        .timeout { color: #856404; } /* Amber/Yellow for timeouts */
        .total { color: #990000; } /* DTU Corporate Red */
        
        .diagnostics {
            padding: 15px;
            display: flex;
            flex-direction: column;
            gap: 12px;
        }
        
        .category-section {
            margin-bottom: 8px;
        }
        
        .category-header {
            font-size: 1.1em;
            font-weight: 600;
            color: #000000;
            margin-bottom: 6px;
            padding: 8px 12px;
            background: #f8f9fa;
            border-left: 4px solid #990000;
            border-radius: 4px;
        }
        
        .category-tests {
            display: flex;
            flex-direction: column;
            gap: 3px;
        }
        
        .diagnostic-card {
            background: white;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            overflow: hidden;
            transition: all 0.3s;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }
        
        .diagnostic-card:hover {
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            transform: translateY(-2px);
        }
        
        .diagnostic-header {
            padding: 8px 12px;
            cursor: pointer;
            user-select: none;
            background: #f8f9fa;
            transition: background-color 0.3s;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .diagnostic-header:hover {
            background: #e9ecef;
        }
        
        .diagnostic-info {
            display: flex;
            flex-direction: column;
            flex: 1;
        }
        
        .diagnostic-name {
            font-weight: 600;
            font-size: 0.95em;
            margin-bottom: 1px;
            color: #000000;
        }
        
        .diagnostic-expand-hint {
            font-size: 0.75em;
            color: #6c757d;
            font-style: italic;
        }
        
        .diagnostic-status-section {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .diagnostic-status {
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 0.75em;
            font-weight: 600;
            text-transform: uppercase;
            display: flex;
            align-items: center;
            gap: 4px;
        }
        
        .diagnostic-status::before {
            content: '';
            width: 6px;
            height: 6px;
            border-radius: 50%;
            display: inline-block;
        }
        
        .status-pass {
            background: rgba(0, 136, 53, 0.1);
            color: #008835;
        }
        
        .status-pass::before {
            background: #008835;
        }
        
        .status-fail {
            background: rgba(232, 63, 72, 0.1);
            color: #E83F48;
        }
        
        .status-fail::before {
            background: #E83F48;
        }
        
        .status-timeout {
            background: rgba(255, 193, 7, 0.1);
            color: #856404;
        }
        
        .status-timeout::before {
            background: #ffc107;
        }
        
        
        .diagnostic-details {
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.4s ease-out;
            background: #1e1e1e;
            color: #d4d4d4;
        }
        
        .diagnostic-card.expanded .diagnostic-details {
            max-height: 450px;
        }
        
        .diagnostic-log {
            padding: 20px;
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
            font-size: 0.85em;
            line-height: 1.3;
            white-space: pre-wrap;
            word-wrap: break-word;
            overflow-y: auto;
            max-height: 400px;
            border-top: 3px solid #990000;
        }
        
        .copy-command-btn {
            background: #007bff;
            color: white;
            border: none;
            padding: 6px 12px;
            font-size: 0.8em;
            border-radius: 4px;
            cursor: pointer;
            margin-right: 8px;
            transition: background-color 0.3s ease;
            font-family: inherit;
        }
        
        .copy-command-btn:hover {
            background: #0056b3;
        }
        
        .copy-command-btn:active {
            transform: translateY(1px);
        }
        
        .copy-command-section {
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            border-left: 4px solid #ffc107;
            border-radius: 6px;
            padding: 15px;
            margin-bottom: 15px;
        }
        
        .copy-command-text {
            color: #495057;
            font-size: 0.9em;
            margin-bottom: 8px;
            font-weight: 500;
        }
        
        .copy-command-line {
            display: flex;
            align-items: center;
            gap: 8px;
            background: #ffffff;
            border: 1px solid #dee2e6;
            border-radius: 4px;
            padding: 8px 12px;
        }
        
        .copy-command-code {
            flex: 1;
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
            font-size: 0.85em;
            color: #212529;
            background: transparent;
            border: none;
        }
        
        .copy-icon-btn {
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 4px;
            padding: 6px;
            cursor: pointer;
            display: flex;
            align-items: center;
            color: #6c757d;
            transition: all 0.2s ease;
        }
        
        .copy-icon-btn:hover {
            background: #e9ecef;
            border-color: #adb5bd;
            color: #495057;
        }
        
        .copy-icon-btn:active {
            transform: translateY(1px);
        }
        
        .subcategory-header {
            font-size: 1.1em;
            font-weight: 600;
            color: #495057;
            margin: 20px 0 15px 0;
            padding: 12px 16px;
            background: linear-gradient(90deg, #f8f9fa 0%, #e9ecef 100%);
            border-radius: 6px;
            border-left: 4px solid #990000;
            text-transform: capitalize;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }
        
        .category-section {
            margin-bottom: 40px;
            border-radius: 8px;
            background: #ffffff;
            border: 1px solid #e9ecef;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .category-header {
            font-size: 1.4em;
            font-weight: 700;
            color: #ffffff;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #990000 0%, #cc0000 100%);
            text-align: center;
            text-transform: uppercase;
            letter-spacing: 1px;
            border: none;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .category-container {
            padding: 20px;
            background: #ffffff;
        }
        
        .category-tests {
            margin-bottom: 15px;
        }
        
        footer {
            text-align: center;
            padding: 30px 20px;
            background: #990000; /* DTU Corporate Red */
            color: #ffffff; /* DTU White */
            font-size: 0.9em;
        }
        
        footer p {
            margin: 5px 0;
        }
        
        .footer-logo {
            height: 30px;
            margin: 10px 0;
            filter: brightness(0) invert(1); /* Make logo white */
        }
        
        .notice {
            background: #fff3cd;
            border: 1px solid #ffc107;
            border-radius: 5px;
            padding: 15px;
            margin: 20px 30px;
            color: #856404;
        }
        
        .notice-title {
            font-weight: bold;
            margin-bottom: 5px;
        }

        /* Scrollbar styling */
        .diagnostic-log::-webkit-scrollbar,
        .sidebar::-webkit-scrollbar,
        .diagnostics::-webkit-scrollbar {
            width: 8px;
        }
        
        .diagnostic-log::-webkit-scrollbar-track,
        .sidebar::-webkit-scrollbar-track,
        .diagnostics::-webkit-scrollbar-track {
            background: #f1f1f1;
        }
        
        .diagnostic-log::-webkit-scrollbar-thumb,
        .sidebar::-webkit-scrollbar-thumb,
        .diagnostics::-webkit-scrollbar-thumb {
            background: #888;
            border-radius: 4px;
        }
        
        .diagnostic-log::-webkit-scrollbar-thumb:hover,
        .sidebar::-webkit-scrollbar-thumb:hover,
        .diagnostics::-webkit-scrollbar-thumb:hover {
            background: #555;
        }
        
        /* Mobile responsive */
        @media (max-width: 768px) {
            .container {
                margin: 10px;
            }
            
            .diagnostics {
                padding: 15px;
            }
            
            .diagnostic-header {
                padding: 10px;
                flex-direction: column;
                align-items: flex-start;
                gap: 8px;
            }
            
            .diagnostic-status-section {
                align-self: flex-end;
            }
            
            .diagnostic-log {
                padding: 15px;
                font-size: 0.8em;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <img src="https://designguide.dtu.dk/-/media/subsites/designguide/design-basics/logo/dtu_logo_corporate_red_rgb.png" 
                 alt="DTU Logo" class="dtu-logo" onerror="this.style.display='none'">
            <h1>$PROFILE_NAME - DTU Python Diagnostics Report</h1>
            <div class="timestamp">Generated on: <span id="timestamp"></span></div>
        </header>
            
            <div class="summary">
                <div class="summary-item">
                    <div class="summary-number passed" id="passed-count">0</div>
                    <div class="summary-label">Passed</div>
                </div>
                <div class="summary-item">
                    <div class="summary-number failed" id="failed-count">0</div>
                    <div class="summary-label">Failed</div>
                </div>
                <div class="summary-item">
                    <div class="summary-number timeout" id="timeout-count">0</div>
                    <div class="summary-label">Timeout</div>
                </div>
                <div class="summary-item">
                    <div class="summary-number total" id="total-count">0</div>
                    <div class="summary-label">Total Checks</div>
                </div>
            </div>
            
            <div class="download-section">
                <button class="download-button" onclick="downloadReport()" id="download-btn">
                    Download Report
                </button>
                <button class="download-button" onclick="emailSupport()" id="email-btn">
                    Email Support
                </button>
            </div>
            
            <div class="notice">
                <div class="notice-title">$PROFILE_NAME Diagnostics Overview</div>
                $PROFILE_DESCRIPTION Click any test to view detailed logs.
            </div>
            
            <div class="diagnostics" id="diagnostics-container">
                <!-- Diagnostic items will be inserted here -->
            </div>
            
        <footer>
            <img src="https://designguide.dtu.dk/-/media/subsites/designguide/design-basics/logo/dtu_logo_corporate_red_rgb.png" 
                 alt="DTU Logo" class="footer-logo" onerror="this.style.display='none'">
            <p><strong>DTU Python Support</strong></p>
            <p>Technical University of Denmark | Danmarks Tekniske Universitet</p>
            <p>Auto-discovered diagnostic components with clean Summary/Details view</p>
        </footer>
    </div>
    
    <script>
        // Embedded diagnostic data (base64 encoded logs)
        const diagnosticData = {
            $JSON_DATA
        };
        
        // Initialize report
        document.addEventListener('DOMContentLoaded', function() {
            // Set timestamp
            document.getElementById('timestamp').textContent = new Date().toLocaleString();
            
            // Organize data by categories and subcategories
            const categories = {};
            let passed = 0;
            let failed = 0;
            let timeout = 0;
            
            for (const [key, data] of Object.entries(diagnosticData)) {
                if (data.status === 'PASS') passed++;
                else if (data.status === 'TIMEOUT') timeout++;
                else failed++;
                
                const categoryKey = data.category;
                const subcategoryKey = data.subcategory || 'General';
                
                if (!categories[categoryKey]) {
                    categories[categoryKey] = {};
                }
                if (!categories[categoryKey][subcategoryKey]) {
                    categories[categoryKey][subcategoryKey] = [];
                }
                categories[categoryKey][subcategoryKey].push({key, ...data});
            }
            
            // Generate diagnostic cards
            generateDiagnosticCards(categories);
            
            // Update summary
            document.getElementById('passed-count').textContent = passed;
            document.getElementById('failed-count').textContent = failed;
            document.getElementById('timeout-count').textContent = timeout;
            document.getElementById('total-count').textContent = passed + failed + timeout;
        });
        
        
        function generateDiagnosticCards(categories) {
            const container = document.getElementById('diagnostics-container');
            
            // Create sections for each category and subcategory
            for (const [categoryName, subcategories] of Object.entries(categories)) {
                // Create category section
                const categorySection = document.createElement('div');
                categorySection.className = 'category-section';
                
                // Create category header
                const categoryHeader = document.createElement('div');
                categoryHeader.className = 'category-header';
                categoryHeader.textContent = categoryName;
                categorySection.appendChild(categoryHeader);
                
                // Create container for subcategories
                const categoryContainer = document.createElement('div');
                categoryContainer.className = 'category-container';
                
                // Process each subcategory
                for (const [subcategoryName, items] of Object.entries(subcategories)) {
                    // Create subcategory header if there are multiple subcategories
                    if (Object.keys(subcategories).length > 1) {
                        const subcategoryHeader = document.createElement('div');
                        subcategoryHeader.className = 'subcategory-header';
                        subcategoryHeader.textContent = subcategoryName;
                        categoryContainer.appendChild(subcategoryHeader);
                    }
                    
                    // Create tests container for this subcategory
                    const testsContainer = document.createElement('div');
                    testsContainer.className = 'category-tests';
                    
                    // Create cards for items in this subcategory
                    items.forEach(item => {
                        // Decode log data
                        let logContent = '';
                        try {
                            logContent = item.log ? atob(item.log) : 'No log data available';
                        } catch (e) {
                            logContent = 'Error decoding log data';
                        }
                        
                        // No manual command extraction needed
                        
                        // Create diagnostic card
                        const card = document.createElement('div');
                        card.className = 'diagnostic-card';
                        card.id = `item-${item.key}`;
                        
                        // No copy button needed
                        
                        card.innerHTML = `
                            <div class="diagnostic-header" onclick="toggleDetails(this)">
                                <div class="diagnostic-info">
                                    <div class="diagnostic-name">${item.name}</div>
                                    <div class="diagnostic-expand-hint">Click to expand</div>
                                </div>
                                <div class="diagnostic-status-section">
                                    <span class="diagnostic-status status-${item.status.toLowerCase()}">
                                        ${item.status}
                                    </span>
                                </div>
                            </div>
                            <div class="diagnostic-details">
                                <div class="diagnostic-log">${escapeHtml(logContent)}</div>
                            </div>
                        `;
                        
                        testsContainer.appendChild(card);
                    });
                    
                    categoryContainer.appendChild(testsContainer);
                }
                
                categorySection.appendChild(categoryContainer);
                container.appendChild(categorySection);
            }
        }
        
        
        function toggleDetails(header) {
            const card = header.parentElement;
            card.classList.toggle('expanded');
        }
        
        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        
        function emailSupport() {
            // Generate summary for email
            const summaryData = generateEmailSummary();
            
            // Create email content with verbose system report
            const subject = 'DTU Python Support - Diagnostic Report';
            const body = `Hello DTU Python Support Team,

I've run the diagnostic report and would like assistance with my Python development environment setup.

${summaryData.verboseReport}

Please let me know how to resolve any issues found.

Best regards,
[Your Name]
[Your Student ID / Email]

---
This email was generated automatically by the DTU Python Diagnostics Report.
Report generated: ${new Date().toLocaleString()}
Browser: ${navigator.userAgent}`;

            // Create mailto link
            const mailtoLink = `mailto:pythonsupport@dtu.dk?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
            
            // Try to open email client
            window.location.href = mailtoLink;
        }
        
        function downloadReport() {
            // Get the current HTML content
            const htmlContent = document.documentElement.outerHTML;
            
            // Create a blob with the HTML content
            const blob = new Blob([htmlContent], { type: 'text/html' });
            
            // Create a download link
            const link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            link.download = `DTU_Python_Diagnostics_${new Date().toISOString().slice(0,19).replace(/:/g, '-')}.html`;
            
            // Trigger the download
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            
            // Clean up the URL object
            URL.revokeObjectURL(link.href);
        }
        
        function generateEmailSummary() {
            let passed = 0, failed = 0, timeout = 0;
            const failures = [];
            const detailedResults = [];
            let systemInfo = '';
            
            // Get system information if available
            if (diagnosticData._system_info && diagnosticData._system_info.systemInfo) {
                systemInfo = diagnosticData._system_info.systemInfo;
            }
            
            for (const [key, data] of Object.entries(diagnosticData)) {
                // Skip system info entry
                if (key === '_system_info') continue;
                
                if (data.status === 'PASS') {
                    passed++;
                    detailedResults.push(`✓ PASSED - ${data.name} (${data.category})`);
                } else if (data.status === 'TIMEOUT') {
                    timeout++;
                    detailedResults.push(`⚠ TIMEOUT - ${data.name} (${data.category})`);
                    failures.push(`- ${data.name} (${data.category}) - TIMEOUT`);
                } else if (data.status === 'FAIL') {
                    failed++;
                    detailedResults.push(`✗ FAILED - ${data.name} (${data.category})`);
                    failures.push(`- ${data.name} (${data.category}) - FAILED`);
                }
            }
            
            const summary = `Total Diagnostics: ${passed + failed + timeout}
Passed: ${passed}
Failed: ${failed}
Timeout: ${timeout}`;
            
            const verboseReport = systemInfo + '\n=== DIAGNOSTIC RESULTS ===\n' + detailedResults.join('\n');
            
            return {
                summary,
                failures: failures.length > 0 ? '\n' + failures.join('\n') : '',
                verboseReport: verboseReport
            };
        }
        
        function copyToClipboard(command, button) {
            // Try to use the Clipboard API first
            if (navigator.clipboard) {
                navigator.clipboard.writeText(command).then(function() {
                    showCopyFeedback(button, true);
                }, function() {
                    // Fallback to execCommand
                    copyToClipboardFallback(command, button);
                });
            } else {
                copyToClipboardFallback(command, button);
            }
        }
        
        function copyToClipboardFallback(command, button) {
            // Create a temporary textarea element
            const textarea = document.createElement('textarea');
            textarea.value = command;
            textarea.style.position = 'fixed';
            textarea.style.opacity = '0';
            document.body.appendChild(textarea);
            
            try {
                textarea.select();
                const successful = document.execCommand('copy');
                showCopyFeedback(button, successful);
            } catch (err) {
                showCopyFeedback(button, false);
            }
            
            document.body.removeChild(textarea);
        }
        
        function showCopyFeedback(button, success) {
            const originalContent = button.innerHTML;
            const originalColor = button.style.color;
            const originalBackground = button.style.background;
            
            if (success) {
                button.innerHTML = '✓';
                button.style.background = '#d4edda';
                button.style.color = '#155724';
                button.style.borderColor = '#c3e6cb';
            } else {
                button.innerHTML = '✗';
                button.style.background = '#f8d7da';
                button.style.color = '#721c24';
                button.style.borderColor = '#f5c6cb';
            }
            
            setTimeout(() => {
                button.innerHTML = originalContent;
                button.style.background = originalBackground;
                button.style.color = originalColor;
                button.style.borderColor = '';
            }, 2000);
        }
        
    </script>
</body>
</html>
HTML_TEMPLATE
    } | sed "s|\$PROFILE_NAME|$PROFILE_NAME|g" | sed "s|\$PROFILE_DESCRIPTION|$PROFILE_DESCRIPTION|g" | sed "s|\$JSON_DATA|$JSON_DATA|g"
}

# ====================================================================
# SECTION 3: COMPONENT DISCOVERY & DIAGNOSTIC EXECUTION
# ====================================================================

# Load components from profile
echo "═══════════════════════════════════════"
discover_components > "$TEMP_DIR/components.sh"
source "$TEMP_DIR/components.sh"
echo "═══════════════════════════════════════"
echo ""

# Track overall results
TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_TIMEOUT=0
JSON_DATA=""
current_category=""

# Capture system information for email summary
SYSTEM_INFO_TEXT=""
SYSTEM_INFO_TEXT+="DTU Python Diagnostics System Report\n"
SYSTEM_INFO_TEXT+="Generated: $(date '+%Y-%m-%d %H:%M:%S')\n"
SYSTEM_INFO_TEXT+="Profile: $PROFILE_NAME\n"
SYSTEM_INFO_TEXT+="\n"
SYSTEM_INFO_TEXT+="=== SYSTEM INFORMATION ===\n"
SYSTEM_INFO_TEXT+="macOS Information:\n"
SYSTEM_INFO_TEXT+="  Product Name: $(sw_vers -productName 2>/dev/null || echo 'Unknown')\n"
SYSTEM_INFO_TEXT+="  Version: $(sw_vers -productVersion 2>/dev/null || echo 'Unknown')\n"
SYSTEM_INFO_TEXT+="  Build: $(sw_vers -buildVersion 2>/dev/null || echo 'Unknown')\n"
SYSTEM_INFO_TEXT+="\n"
SYSTEM_INFO_TEXT+="Hardware Information:\n"
SYSTEM_INFO_TEXT+="  Architecture: $(uname -m 2>/dev/null || echo 'Unknown')\n"
SYSTEM_INFO_TEXT+="  Hostname: $(hostname 2>/dev/null || echo 'Unknown')\n"
SYSTEM_INFO_TEXT+="  Kernel: $(uname -sr 2>/dev/null || echo 'Unknown')\n"
if command -v system_profiler >/dev/null 2>&1; then
    cpu_info=$(timeout 3 system_profiler SPHardwareDataType 2>/dev/null | grep "Processor Name" | cut -d':' -f2 | sed 's/^ *//' || echo 'Unknown')
    memory_info=$(timeout 3 system_profiler SPHardwareDataType 2>/dev/null | grep "Memory" | cut -d':' -f2 | sed 's/^ *//' || echo 'Unknown')
    SYSTEM_INFO_TEXT+="  Processor: $cpu_info\n"
    SYSTEM_INFO_TEXT+="  Memory: $memory_info\n"
fi
SYSTEM_INFO_TEXT+="\n"
SYSTEM_INFO_TEXT+="User Environment:\n"
SYSTEM_INFO_TEXT+="  Username: $(whoami 2>/dev/null || echo 'Unknown')\n"
SYSTEM_INFO_TEXT+="  Home Directory: $HOME\n"
SYSTEM_INFO_TEXT+="  Current Shell: $SHELL\n"
SYSTEM_INFO_TEXT+="  PATH Entries: $(echo $PATH | tr ':' '\n' | wc -l | tr -d ' ') directories\n"
SYSTEM_INFO_TEXT+="\n"
SYSTEM_INFO_TEXT+="Development Tools Overview:\n"
for tool in python python3 pip pip3 conda brew code git; do
    if command -v "$tool" >/dev/null 2>&1; then
        tool_path=$(which "$tool" 2>/dev/null)
        case "$tool" in
            python|python3)
                version=$($tool --version 2>/dev/null | head -1)
                ;;
            pip|pip3)
                version=$($tool --version 2>/dev/null | head -1 | awk '{print $2}')
                version="version $version"
                ;;
            conda)
                version=$($tool --version 2>/dev/null | head -1)
                version="version $(echo "$version" | awk '{print $2}')"
                ;;
            brew)
                version="version $($tool --version 2>/dev/null | head -1 | awk '{print $2}')"
                ;;
            code)
                version=$($tool --version 2>/dev/null | head -1)
                version="version $version"
                ;;
            git)
                version=$($tool --version 2>/dev/null | awk '{print $3}')
                version="version $version"
                ;;
        esac
        SYSTEM_INFO_TEXT+="  ✓ $tool: $version ($tool_path)\n"
    else
        SYSTEM_INFO_TEXT+="  ✗ $tool: Not found\n"
    fi
done
SYSTEM_INFO_TEXT+="\n"
SYSTEM_INFO_TEXT+="Python Environment Variables:\n"
for var in PYTHONPATH VIRTUAL_ENV CONDA_DEFAULT_ENV PYTHONHOME; do
    if [[ -n "${!var}" ]]; then
        SYSTEM_INFO_TEXT+="  $var: ${!var}\n"
    else
        SYSTEM_INFO_TEXT+="  $var: (not set)\n"
    fi
done
SYSTEM_INFO_TEXT+="\n"

# Run all discovered diagnostic components
echo "Running diagnostic checks..."
if [[ "$PARALLEL_ENABLED" == "true" ]]; then
    echo "Mode: Parallel (max $MAX_PARALLEL concurrent checks)"
else
    echo "Mode: Sequential"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ "$PARALLEL_ENABLED" == "true" ]]; then
    # Parallel execution
    active_jobs=0
    job_pids=()
    job_info=()
    
    echo -e "\n${BLUE}Starting parallel diagnostics...${NC}"
    echo "────────────────────────"
    
    for category_data in "${DISCOVERED_CATEGORIES[@]}"; do
        IFS=':' read -r main_category subcategory script_name display_name script_path <<< "$category_data"
        
        # Wait for a slot if we're at max parallel jobs
        while [[ $active_jobs -ge $MAX_PARALLEL ]]; do
            for i in "${!job_pids[@]}"; do
                if ! kill -0 "${job_pids[$i]}" 2>/dev/null; then
                    unset job_pids[$i]
                    ((active_jobs--))
                    break
                fi
            done
            sleep 0.1
        done
        
        echo "  Launching: $main_category > $subcategory → $display_name"
        run_diagnostic_parallel "$main_category" "$subcategory" "$script_name" "$display_name" "$script_path"
        job_pids+=($!)
        job_info+=("$main_category:$subcategory:$script_name:$display_name")
        ((active_jobs++))
    done
    
    # Wait for all jobs to complete
    echo -e "\n${BLUE}Waiting for all checks to complete...${NC}"
    wait
    
    echo -e "\n${BLUE}Results:${NC}"
    echo "────────────────────────"
    
    # Process results
    for category_data in "${DISCOVERED_CATEGORIES[@]}"; do
        IFS=':' read -r main_category subcategory script_name display_name script_path <<< "$category_data"
        
        # Check if this is a new category
        category_display="$main_category > $subcategory"
        if [[ "$category_display" != "$current_category" ]]; then
            current_category="$category_display"
            echo -e "\n${BLUE}Category: $category_display${NC}"
        fi
        
        # Read status from file
        category_key="${main_category}_${subcategory//\//_}"
        status_file="$TEMP_DIR/status_${category_key}_${script_name%.sh}"
        if [[ -f "$status_file" ]]; then
            exit_code=$(cat "$status_file")
            if [[ "$exit_code" == "0" ]]; then
                STATUS="PASS"
                echo -e "  ${GREEN}✓ PASSED${NC} - $display_name"
                ((TOTAL_PASS++))
            elif [[ "$exit_code" == "124" ]]; then
                STATUS="TIMEOUT"
                echo -e "  ${YELLOW}⚠ TIMEOUT${NC} - $display_name"
                ((TOTAL_TIMEOUT++))
            else
                STATUS="FAIL"
                echo -e "  ${RED}✗ FAILED (exit code: $exit_code)${NC} - $display_name"
                ((TOTAL_FAIL++))
            fi
        else
            STATUS="FAIL"
            echo -e "  ${RED}✗ ERROR (no status file)${NC} - $display_name"
            ((TOTAL_FAIL++))
        fi
        
        # Get log content and base64 encode it
        log_file="$LOG_DIR/${category_key}_${script_name%.sh}.log"
        LOG_DATA=""
        if [[ -f "$log_file" ]]; then
            # Extract execution time if available
            exec_time=$(grep "^EXEC_TIME:" "$log_file" | cut -d':' -f2)
            if [[ -n "$exec_time" ]]; then
                echo "    Script path: $script_path"
                echo "    Execution time: ${exec_time}s"
            fi
            LOG_DATA=$(grep -v "^EXEC_TIME:" "$log_file" | base64 2>/dev/null | tr -d '\n' || echo "")
        fi
        
        # Build JSON data
        if [[ -n "$JSON_DATA" ]]; then
            JSON_DATA="${JSON_DATA},"
        fi
        JSON_DATA="${JSON_DATA}
            '${category_key}_${script_name}': {
                category: '${main_category}',
                subcategory: '${subcategory}',
                name: '${display_name}',
                status: '${STATUS}',
                log: '${LOG_DATA}'
            }"
    done
else
    # Sequential execution (original code)
    for category_data in "${DISCOVERED_CATEGORIES[@]}"; do
        IFS=':' read -r main_category subcategory script_name display_name script_path <<< "$category_data"
        
        # Check if this is a new category
        category_display="$main_category > $subcategory"
        if [[ "$category_display" != "$current_category" ]]; then
            current_category="$category_display"
            echo -e "\n${BLUE}Category: $category_display${NC}"
            echo "────────────────────────"
        fi
        
        STATUS="FAIL"
        if run_diagnostic "$main_category" "$subcategory" "$script_name" "$display_name" "$script_path"; then
            STATUS="PASS"
            ((TOTAL_PASS++))
        else
            exit_code=$?
            if [[ $exit_code -eq 124 ]]; then
                STATUS="TIMEOUT"
                ((TOTAL_TIMEOUT++))
            else
                ((TOTAL_FAIL++))
            fi
        fi
        
        # Get log content and base64 encode it
        category_key="${main_category}_${subcategory//\//_}"
        log_file="$LOG_DIR/${category_key}_${script_name%.sh}.log"
        LOG_DATA=""
        if [[ -f "$log_file" ]]; then
            # Extract execution time if available
            exec_time=$(grep "^EXEC_TIME:" "$log_file" | cut -d':' -f2)
            if [[ -n "$exec_time" ]]; then
                echo "    Execution time: ${exec_time}s"
            fi
            LOG_DATA=$(grep -v "^EXEC_TIME:" "$log_file" | base64 2>/dev/null | tr -d '\n' || echo "")
        fi
        
        # Build JSON data
        if [[ -n "$JSON_DATA" ]]; then
            JSON_DATA="${JSON_DATA},"
        fi
        JSON_DATA="${JSON_DATA}
            '${category_key}_${script_name}': {
                category: '${main_category}',
                subcategory: '${subcategory}',
                name: '${display_name}',
                status: '${STATUS}',
                log: '${LOG_DATA}'
            }"
    done
fi

# Wrap JSON_DATA in proper JavaScript object literal format, including system information
SYSTEM_INFO_ESCAPED=$(echo "$SYSTEM_INFO_TEXT" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/$/\\n/' | tr -d '\n' | sed 's/\\n$//')

if [[ -n "$JSON_DATA" ]]; then
    JSON_DATA="{$JSON_DATA,
        '_system_info': {
            category: 'System',
            subcategory: 'Information',
            name: 'System Information',
            status: 'INFO',
            log: '$(echo "$SYSTEM_INFO_ESCAPED" | base64 2>/dev/null | tr -d '\n' || echo "")',
            systemInfo: '$SYSTEM_INFO_ESCAPED'
        }
    }"
else
    JSON_DATA="{
        '_system_info': {
            category: 'System',
            subcategory: 'Information', 
            name: 'System Information',
            status: 'INFO',
            log: '$(echo "$SYSTEM_INFO_ESCAPED" | base64 2>/dev/null | tr -d '\n' || echo "")',
            systemInfo: '$SYSTEM_INFO_ESCAPED'
        }
    }"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ====================================================================
# SECTION 4: HTML REPORT GENERATION
# ====================================================================

# ====================================================================
# TEMPLATE PROCESSING FUNCTIONS
# ====================================================================

# Function to load template files
load_template_file() {
    local file_path="$1"
    local temp_file="$2"
    
    if [[ "${BASH_SOURCE[0]}" == "/dev/stdin" ]] || [[ "${BASH_SOURCE[0]}" == "bash" ]]; then
        # Running remotely via curl - download template from repository
        if download_repo_file "MacOS/Components/Diagnostics/$file_path" "$temp_file"; then
            cat "$temp_file"
            return 0
        fi
    else
        # Running locally
        local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        local local_file="$SCRIPT_DIR/$file_path"
        if [[ -f "$local_file" ]]; then
            cat "$local_file"
            return 0
        fi
    fi
    return 1
}

# Function to process template placeholders using robust multi-line replacement
process_template() {
    local template_content="$1"
    local css_content="$2"
    local js_content="$3"
    local json_data="$4"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Create temporary files for content
    local temp_template="$TEMP_DIR/template_processing.html"
    local temp_css="$TEMP_DIR/css_content.txt" 
    local temp_js="$TEMP_DIR/js_content.txt"
    local temp_json="$TEMP_DIR/json_data.txt"
    local process_script="$TEMP_DIR/process_template.sh"
    
    # Write content to temporary files to avoid shell escaping issues
    echo "$template_content" > "$temp_template"
    echo "$css_content" > "$temp_css"
    echo "$js_content" > "$temp_js"
    echo "$json_data" > "$temp_json"
    
    # Create a robust processing script using bash parameter expansion
    cat > "$process_script" << 'EOF'
#!/bin/bash
template_file="$1"
css_file="$2"  
js_file="$3"
json_file="$4"
profile_name="$5"
profile_desc="$6"
timestamp="$7"

# Function to safely replace content in template
replace_placeholder() {
    local template="$1"
    local placeholder="$2" 
    local content_file="$3"
    
    if [[ "$template" == *"$placeholder"* ]]; then
        # Find the placeholder position and split the template
        local before="${template%%$placeholder*}"
        local after="${template##*$placeholder}"
        local content
        content=$(cat "$content_file")
        
        # Reconstruct template with content inserted
        template="${before}${content}${after}"
    fi
    
    echo "$template"
}

# Function to replace simple string placeholders  
replace_simple() {
    local template="$1"
    local placeholder="$2"
    local replacement="$3"
    
    # Use parameter expansion for simple string replacement
    echo "${template//$placeholder/$replacement}"
}

# Read the template
template_content=$(cat "$template_file")

# Simple string replacements first
template_content=$(replace_simple "$template_content" "{{PROFILE_NAME}}" "$profile_name")
template_content=$(replace_simple "$template_content" "{{PROFILE_DESCRIPTION}}" "$profile_desc")
template_content=$(replace_simple "$template_content" "{{TIMESTAMP}}" "$timestamp")
template_content=$(replace_simple "$template_content" "{{SUMMARY_HTML}}" "")

# Handle CSS content replacement
template_content=$(replace_placeholder "$template_content" "{{CSS_CONTENT}}" "$css_file")

# Handle JS content replacement (first replace DIAGNOSTIC_DATA in JS file)
if [[ -f "$js_file" ]]; then
    json_content=$(cat "$json_file")
    js_content=$(cat "$js_file")
    # Replace DIAGNOSTIC_DATA placeholder in JS content
    js_content=${js_content//\{\{DIAGNOSTIC_DATA\}\}/$json_content}
    # Write updated JS content back to file
    echo "$js_content" > "$js_file"
fi

# Replace JS content in template
template_content=$(replace_placeholder "$template_content" "{{JS_CONTENT}}" "$js_file")

# Output the processed template
printf '%s\n' "$template_content"
EOF
        
    chmod +x "$process_script"
    "$process_script" "$temp_template" "$temp_css" "$temp_js" "$temp_json" "$PROFILE_NAME" "$PROFILE_DESCRIPTION" "$timestamp"
}

# Generate HTML report using template system
echo "Generating HTML report using template system..."
echo "Profile: $PROFILE_NAME"

# Ensure we have write access to report location
if ! touch "$REPORT_FILE" 2>/dev/null; then
    echo -e "${RED}Error: Cannot write to $REPORT_FILE${NC}"
    echo "Trying alternative location..."
    if [[ "$SELECTED_PROFILE" != "comprehensive" ]]; then
        REPORT_FILE="/tmp/DTU_Python_Diagnostics_${SELECTED_PROFILE}_$(date +%Y%m%d_%H%M%S).html"
    else
        REPORT_FILE="/tmp/DTU_Python_Diagnostics_$(date +%Y%m%d_%H%M%S).html"
    fi
    echo "Using: $REPORT_FILE"
fi

# Load template files
echo "Loading template files..."
html_template=$(load_template_file "templates/base.html" "$TEMP_DIR/base.html")
css_content=$(load_template_file "templates/styles.css" "$TEMP_DIR/styles.css")
js_content=$(load_template_file "templates/scripts.js" "$TEMP_DIR/scripts.js")

# Check if templates loaded successfully
if [[ -z "$html_template" ]] || [[ -z "$css_content" ]] || [[ -z "$js_content" ]]; then
    echo -e "${YELLOW}Warning: Could not load some template files. Using embedded fallback templates.${NC}"
    
    # Fallback to embedded templates
    generate_fallback_report
else
    echo "Templates loaded successfully. Processing..."
    
    # Generate report with templates
    {
        process_template "$html_template" "$css_content" "$js_content" "$JSON_DATA"
    } > "$REPORT_FILE" || {
        echo -e "${RED}Error generating HTML report with templates${NC}"
        echo "Falling back to embedded template..."
        generate_fallback_report
    }
fi

echo "Report generated successfully!"
echo ""
echo "Summary:"
echo "   Passed:  $TOTAL_PASS"
echo "   Failed:  $TOTAL_FAIL"
echo "   Timeout: $TOTAL_TIMEOUT"
echo "   Total:   $((TOTAL_PASS + TOTAL_FAIL + TOTAL_TIMEOUT))"
echo ""
echo "Report saved to: $REPORT_FILE"
echo ""

# ====================================================================
# SECTION 5: FINALIZATION & CLEANUP
# ====================================================================

# Open the report in default browser
if [[ "$REPORT_FILE" == *.html ]] && command -v open >/dev/null 2>&1; then
    echo "Opening report in browser..."
    open "$REPORT_FILE"
fi

# Temp directory will be automatically cleaned up by trap on exit
echo "Temporary files will be automatically cleaned up"

exit 0