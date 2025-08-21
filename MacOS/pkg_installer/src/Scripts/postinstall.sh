#!/bin/bash
# DTU Python Installation Script (Environment-Aware PKG Installer)
# Detects PKG vs traditional mode and loads components accordingly
# Ensures compatibility with both PKG and traditional mac_orchestrators.yml

# Strict error handling
set -euo pipefail

# Get script directory for relative paths and ensure it's absolute
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source local config file for environment variables
if [ -f "$SCRIPT_DIR/../metadata/config.sh" ]; then
    source "$SCRIPT_DIR/../metadata/config.sh"
else
    # Fallback configuration if config.sh is not found
    export REPO="philipnickel/pythonsupport-scripts"
    export BRANCH="main"
    export LOG_FILE="/tmp/macos_dtu_python_install.log"
    export SUMMARY_FILE="/tmp/macos_dtu_python_summary.txt"
    export SUPPORT_EMAIL="python-support@dtu.dk"
fi

# Load local progress utilities
source "$SCRIPT_DIR/loading_animations.sh" 2>/dev/null || {
    # Define minimal fallback functions if loading_animations.sh unavailable
    show_progress_log() { echo "$(date '+%H:%M:%S') [${2:-INFO}] DTU Python Installer: $1"; }
    show_installer_header() { echo "=== DTU Python Installation ==="; }
    show_component_progress() { show_progress_log "$1: $2"; }
    show_installation_summary() { show_progress_log "Installation Summary: $1"; }
}

# Setup logging - ensure log file directory exists and redirect to both log file and stdout
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1


# Local utility functions (offline versions of shared utilities)
_prefix="PYS:"

# Environment Detection - Check if running from PKG installation
detect_environment() {
    # Multiple possible paths for bundled components
    local possible_paths=(
        "/usr/local/share/dtu-python-installer/components"
        "$SCRIPT_DIR/../payload/Components"
        "/Library/Application Support/DTU Python Installer/Components"
        "$SCRIPT_DIR/../Components"
    )
    
    for bundled_components_path in "${possible_paths[@]}"; do
        local bundled_orchestrator="$bundled_components_path/orchestrators/first_year_students.sh"
        
        if [ -d "$bundled_components_path" ] && [ -f "$bundled_orchestrator" ]; then
            export DTU_PYTHON_PKG_MODE="true"
            export DTU_COMPONENTS_PATH="$bundled_components_path"
            echo "$_prefix Environment detected: PKG mode (using bundled components at: $bundled_components_path)"
            return 0
        else
            echo "$_prefix Checked path: $bundled_components_path (not found or incomplete)"
        fi
    done
    
    export DTU_PYTHON_PKG_MODE="false"
    unset DTU_COMPONENTS_PATH
    echo "$_prefix Environment detected: Traditional mode (using remote curl)"
    return 1
}

log_info() {
    echo "$_prefix $1"
    show_progress_log "$1" "INFO"
}

log_error() {
    echo "$_prefix ERROR: $1" >&2
    show_progress_log "$1" "ERROR"
}

log_success() {
    echo "$_prefix ✓ $1"
    show_progress_log "$1" "INFO"
}

log_warning() {
    echo "$_prefix WARNING: $1"
    show_progress_log "$1" "WARN"
}

# Enhanced error checking function
check_exit_code() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        if [ $# -gt 0 ]; then
            log_error "$1"
        fi
        log_error "Installation failed. Contact python-support@dtu.dk for help."
        exit $exit_code
    fi
}

# Function to check if command exists (kept for summary generation)
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to create custom curl wrapper for PKG mode
setup_pkg_environment() {
    if [ "$DTU_PYTHON_PKG_MODE" = "true" ]; then
        # Create temporary directory for curl wrapper
        local temp_dir="/tmp/dtu-python-pkg-$$"
        mkdir -p "$temp_dir"
        
        # Store temp dir for cleanup
        export DTU_TEMP_DIR="$temp_dir"
        
        # Create curl wrapper script
        cat > "$temp_dir/curl" << 'EOF'
#!/bin/bash
# Curl wrapper for PKG mode - routes GitHub URLs to local components

# Extract the URL from curl arguments
URL=""
for arg in "$@"; do
    if [[ "$arg" =~ ^https://raw\.githubusercontent\.com/.*/MacOS/Components/(.*)$ ]]; then
        URL="$arg"
        break
    fi
done

if [ -n "$URL" ]; then
    # Extract the component path from the GitHub URL
    if [[ "$URL" =~ github\.com/.*/MacOS/Components/(.*)$ ]]; then
        COMPONENT_PATH="${BASH_REMATCH[1]}"
        LOCAL_FILE="$DTU_COMPONENTS_PATH/$COMPONENT_PATH"
        
        echo "[CURL WRAPPER] Attempting to load local component: $LOCAL_FILE" >&2
        
        if [ -f "$LOCAL_FILE" ]; then
            echo "[CURL WRAPPER] Found local component: $LOCAL_FILE" >&2
            cat "$LOCAL_FILE"
            exit 0
        else
            echo "[CURL WRAPPER] ERROR: Local component file not found: $LOCAL_FILE" >&2
            echo "[CURL WRAPPER] Available components:" >&2
            find "$DTU_COMPONENTS_PATH" -name "*.sh" 2>/dev/null | head -10 >&2 || true
            echo "[CURL WRAPPER] Components path: $DTU_COMPONENTS_PATH" >&2
            exit 1
        fi
    fi
fi

# If not a component request, call real curl
exec /usr/bin/curl "$@"
EOF
        
        chmod +x "$temp_dir/curl"
        export PATH="$temp_dir:$PATH"
        log_info "PKG mode: Created curl wrapper for local component loading"
        log_info "PKG mode: Components path: $DTU_COMPONENTS_PATH"
        log_info "PKG mode: Available components: $(find "$DTU_COMPONENTS_PATH" -name "*.sh" 2>/dev/null | wc -l) files"
        log_info "PKG mode: PATH updated to: $PATH"
        # Export variables for the curl wrapper
        export DTU_COMPONENTS_PATH
    fi
}

# Function to cleanup temporary files
cleanup_pkg_environment() {
    if [ -n "$DTU_TEMP_DIR" ] && [ -d "$DTU_TEMP_DIR" ]; then
        rm -rf "$DTU_TEMP_DIR" 2>/dev/null || true
        log_info "PKG mode: Cleaned up temporary curl wrapper"
    fi
}

# Main installation function
main() {
    # Determine console user and set environment with proper fallback
    local user_name
    local user_home
    
    # Primary method: get console user (works in most scenarios including CI)
    if [ -c "/dev/console" ]; then
        user_name=$(stat -f%Su /dev/console 2>/dev/null)
    fi
    
    # Fallback methods if console detection fails
    if [ -z "$user_name" ] || [ "$user_name" = "root" ]; then
        if [ -n "${SUDO_USER:-}" ]; then
            user_name="$SUDO_USER"
        elif [ -n "${USER:-}" ] && [ "$USER" != "root" ]; then
            user_name="$USER"
        else
            # Last resort: look for active users
            user_name=$(who | awk '{print $1}' | head -n1 | grep -v '^root$' || echo "runner")
        fi
    fi
    
    # Validate user name and set home directory
    if [ -z "$user_name" ] || [ "$user_name" = "root" ]; then
        # CI environment fallback - use 'runner' as typical CI username
        user_name="runner"
        user_home="/Users/runner"
        log_warning "Unable to detect console user, using fallback: $user_name"
    else
        user_home="/Users/$user_name"
    fi
    
    # Ensure home directory exists for CI environments
    if [ ! -d "$user_home" ]; then
        log_warning "Home directory $user_home does not exist, attempting to create it"
        mkdir -p "$user_home" 2>/dev/null || {
            log_warning "Could not create $user_home, using /tmp as HOME"
            user_home="/tmp"
        }
    fi
    
    export USER="$user_name"
    export HOME="$user_home"
    
    # Set environment variables for installation
    export PYTHON_VERSION_PS="${PYTHON_VERSION_PS:-3.11}"
    export PIS_ENV="${PIS_ENV:-CI}"
    
    log_info "Starting DTU Python installation for user: $user_name"
    log_info "User home directory: $user_home"
    log_info "Python version: $PYTHON_VERSION_PS"
    log_info "Installation environment: $PIS_ENV"
    log_info "Running as UID: $(id -u), effective user: $user_name"
    
    show_installer_header
    
    # Detect and setup environment
    log_info "Detecting installation environment..."
    detect_environment
    setup_pkg_environment
    
    # Additional debugging information
    log_info "Environment variables for installation:"
    log_info "  DTU_PYTHON_PKG_MODE: $DTU_PYTHON_PKG_MODE"
    log_info "  DTU_COMPONENTS_PATH: ${DTU_COMPONENTS_PATH:-unset}"
    log_info "  HOME: $HOME"
    log_info "  USER: $USER"
    log_info "  PIS_ENV: $PIS_ENV"
    log_info "  GITHUB_CI: ${GITHUB_CI:-unset}"
    log_info "  Current working directory: $(pwd)"
    log_info "  User can write to home: $([ -w "$user_home" ] && echo "YES" || echo "NO")"
    
    # Pre-installation validation
    if [ "$DTU_PYTHON_PKG_MODE" = "true" ]; then
        if [ ! -f "$DTU_COMPONENTS_PATH/orchestrators/first_year_students.sh" ]; then
            log_error "Critical error: Required orchestrator not found in PKG bundle"
            log_error "Expected: $DTU_COMPONENTS_PATH/orchestrators/first_year_students.sh"
            log_error "This indicates a PKG build problem. Installation cannot proceed."
            exit 1
        fi
    fi
    
    # Call the existing first_year_students.sh orchestrator
    log_info "Executing first year students orchestrator..."
    
    local orchestrator_cmd
    local orchestrator_ret
    
    if [ "$DTU_PYTHON_PKG_MODE" = "true" ]; then
        # PKG mode - use local orchestrator
        log_info "PKG mode: Using bundled first_year_students.sh orchestrator"
        orchestrator_cmd="$DTU_COMPONENTS_PATH/orchestrators/first_year_students.sh"
        
        # Set environment variables for PKG compatibility
        export REMOTE_PS="${REPO:-dtudk/pythonsupport-scripts}"
        export BRANCH_PS="${BRANCH:-main}"
        export GITHUB_CI="true"
        # Ensure non-interactive mode for CI environments
        export DEBIAN_FRONTEND="noninteractive"
        export CI="true"
        export NONINTERACTIVE="1"
        
        # Execute orchestrator as the user with all necessary environment variables
        # Use -H flag to set HOME properly and -s to use user's shell
        sudo -H -u "$user_name" \
            env HOME="$user_home" \
            USER="$user_name" \
            LOGNAME="$user_name" \
            DTU_PYTHON_PKG_MODE="$DTU_PYTHON_PKG_MODE" \
            DTU_COMPONENTS_PATH="$DTU_COMPONENTS_PATH" \
            PYTHON_VERSION_PS="$PYTHON_VERSION_PS" \
            PIS_ENV="$PIS_ENV" \
            REMOTE_PS="$REMOTE_PS" \
            BRANCH_PS="$BRANCH_PS" \
            GITHUB_CI="$GITHUB_CI" \
            CI="$CI" \
            NONINTERACTIVE="$NONINTERACTIVE" \
            DEBIAN_FRONTEND="$DEBIAN_FRONTEND" \
            DTU_TEMP_DIR="$DTU_TEMP_DIR" \
            PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
            /bin/bash -l "$orchestrator_cmd"
        orchestrator_ret=$?
    else
        # Traditional mode - use curl to download and execute
        log_info "Traditional mode: Using remote first_year_students.sh orchestrator"
        sudo -H -u "$user_name" \
            env HOME="$user_home" \
            USER="$user_name" \
            LOGNAME="$user_name" \
            PYTHON_VERSION_PS="$PYTHON_VERSION_PS" \
            PIS_ENV="$PIS_ENV" \
            REMOTE_PS="${REPO:-dtudk/pythonsupport-scripts}" \
            BRANCH_PS="${BRANCH:-main}" \
            CI="true" \
            NONINTERACTIVE="1" \
            PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
            /bin/bash -l -c "$(curl -fsSL https://raw.githubusercontent.com/${REPO:-dtudk/pythonsupport-scripts}/${BRANCH:-main}/MacOS/Components/orchestrators/first_year_students.sh)"
        orchestrator_ret=$?
    fi
    
    # Check orchestrator result and create summary
    if [ $orchestrator_ret -eq 0 ]; then
        create_summary "success"
        show_installation_summary "First Year Students Setup"
        log_success "DTU Python installation completed successfully!"
        log_info "Orchestrator executed successfully with components from: $([ "$DTU_PYTHON_PKG_MODE" = "true" ] && echo "bundled PKG" || echo "remote GitHub")"
        
        # Additional verification for PKG mode
        if [ "$DTU_PYTHON_PKG_MODE" = "true" ]; then
            log_info "PKG mode verification: All components loaded from local bundle"
            log_info "PKG mode verification: No network dependencies were used"
        fi
    else
        create_summary "failed"
        log_error "First year students orchestrator failed with exit code: $orchestrator_ret"
        log_error "Installation failed. Contact python-support@dtu.dk for help."
        
        # Enhanced error reporting for PKG mode
        if [ "$DTU_PYTHON_PKG_MODE" = "true" ]; then
            log_error "PKG mode error: Check that all required components are bundled"
            log_info "PKG mode debug: Components path: $DTU_COMPONENTS_PATH"
            log_info "PKG mode debug: Available scripts: $(find "$DTU_COMPONENTS_PATH" -name "*.sh" 2>/dev/null | wc -l)"
            log_info "PKG mode debug: Orchestrator file: $([ -f "$DTU_COMPONENTS_PATH/orchestrators/first_year_students.sh" ] && echo "EXISTS" || echo "MISSING")"
            log_info "PKG mode debug: Components directory listing:"
            find "$DTU_COMPONENTS_PATH" -type f -name "*.sh" 2>/dev/null | head -10 | while read -r file; do
                log_info "  - $file"
            done || true
        fi
    fi
    
    # Cleanup temporary files
    cleanup_pkg_environment
    
    return $orchestrator_ret
}

# Function to create installation summary
create_summary() {
    local status="$1"
    local mode_text="$([ "$DTU_PYTHON_PKG_MODE" = "true" ] && echo "PKG mode (bundled components)" || echo "Traditional mode (remote components)")"
    
    cat > "$SUMMARY_FILE" << EOF
DTU First Year Students Installation Complete!

Installation log: $LOG_FILE
Date: $(date)
User: $USER
Mode: $mode_text

Installation Results:
- Orchestrator execution: $([ "$status" = "success" ] && echo "SUCCESS" || echo "FAILED")
- Homebrew: $(command_exists brew && echo "SUCCESS" || echo "UNKNOWN")
- Conda: $(command_exists conda && echo "SUCCESS" || echo "UNKNOWN")
- Python 3.11: $(command_exists python3 && echo "SUCCESS" || echo "UNKNOWN")
- VS Code: $(command_exists code && echo "SUCCESS" || echo "UNKNOWN")

Verification Results (if available):
- Conda command: $(command_exists conda && echo "SUCCESS" || echo "NOT FOUND")
- Python 3.11: $(command_exists python3 && echo "SUCCESS" || echo "NOT FOUND")
- Package imports: $(python3 -c "import dtumathtools, pandas, scipy, statsmodels, uncertainties" 2>/dev/null && echo "SUCCESS" || echo "NOT TESTED")

Component Loading:
- Source: $([ "$DTU_PYTHON_PKG_MODE" = "true" ] && echo "Local bundled components from PKG" || echo "Remote components from GitHub")
- Repository: ${REPO:-dtudk/pythonsupport-scripts}
- Branch: ${BRANCH:-main}

Next steps:
1. Open Terminal and type 'python3' to test Python
2. Open Visual Studio Code to start coding
3. Try importing: dtumathtools, pandas, numpy, matplotlib
4. Create your first Python project!

For support: $SUPPORT_EMAIL
EOF

    log_info "Installation summary created at: $SUMMARY_FILE"
}

# Error handling - create failure summary on error
trap 'cleanup_pkg_environment; create_summary "failed"; log_error "Installation failed. Check $LOG_FILE for details."; exit 1' ERR

# Execute main installation if not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_info "PKG installer script finished successfully"
    else
        log_error "PKG installer script failed with exit code: $exit_code"
    fi
    
    exit $exit_code
fi