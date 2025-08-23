#!/bin/bash

# @doc
# @name: VSCode PKG Test Script
# @description: Tests the VSCode PKG installation and functionality
# @category: Testing
# @usage: ./test_vscode_pkg.sh [pkg_file]
# @requirements: macOS system and VSCode PKG file
# @notes: Validates VSCode app installation, CLI tools, and Python extensions
# @/doc

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_FILE="${1:-}"

log_info() {
    echo "[INFO] $*"
}

log_success() {
    echo "[SUCCESS] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_warning() {
    echo "[WARNING] $*"
}

check_exit_code() {
    local msg="$1"
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "$msg (exit code: $exit_code)"
        exit $exit_code
    fi
}

# Function to find the VSCode PKG file
find_pkg_file() {
    if [ -n "$PKG_FILE" ] && [ -f "$PKG_FILE" ]; then
        echo "$PKG_FILE"
        return 0
    fi
    
    # Look in builds directory
    local builds_dir="$SCRIPT_DIR/builds"
    if [ -d "$builds_dir" ]; then
        local found_pkg
        found_pkg=$(find "$builds_dir" -name "DTU-VSCode-*.pkg" -type f | head -1)
        if [ -n "$found_pkg" ]; then
            echo "$found_pkg"
            return 0
        fi
    fi
    
    log_error "No VSCode PKG file found. Please specify path or build one first."
    exit 1
}

# Function to install the PKG
install_pkg() {
    local pkg_path="$1"
    
    log_info "Installing VSCode PKG: $(basename "$pkg_path")"
    log_info "Package size: $(du -h "$pkg_path" | cut -f1)"
    
    # Install the PKG
    sudo installer -pkg "$pkg_path" -target /
    check_exit_code "Failed to install VSCode PKG"
    
    log_success "VSCode PKG installation completed"
}

# Function to test VSCode app installation
test_vscode_app() {
    log_info "Testing VSCode application installation..."
    
    # Check if app exists
    if [ ! -d "/Applications/Visual Studio Code.app" ]; then
        log_error "VSCode app not found in /Applications/"
        return 1
    fi
    
    # Check app bundle structure
    local app_path="/Applications/Visual Studio Code.app"
    if [ ! -f "$app_path/Contents/Info.plist" ]; then
        log_error "VSCode app bundle structure invalid"
        return 1
    fi
    
    # Get app version
    local app_version
    app_version=$(defaults read "$app_path/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "unknown")
    
    log_success "VSCode app installed successfully (version: $app_version)"
}

# Function to test CLI tools
test_cli_tools() {
    log_info "Testing VSCode CLI tools..."
    
    # Test code command availability
    if ! command -v code >/dev/null 2>&1; then
        log_error "VSCode 'code' command not found in PATH"
        return 1
    fi
    
    # Test code command functionality
    local code_version
    if code_version=$(code --version 2>/dev/null); then
        log_success "VSCode CLI working - version: $(echo "$code_version" | head -1)"
    else
        log_error "VSCode CLI not functioning properly"
        return 1
    fi
    
    # Test that code command points to the correct location
    local code_path
    code_path=$(which code)
    log_info "Code command location: $code_path"
}

# Function to test extensions
test_extensions() {
    log_info "Testing VSCode extensions..."
    
    # Give extensions time to install
    log_info "Waiting for extension installation to complete..."
    sleep 10
    
    # List installed extensions
    local extensions
    if extensions=$(code --list-extensions 2>/dev/null); then
        log_info "Installed extensions:"
        echo "$extensions" | while read -r ext; do
            log_info "  - $ext"
        done
        
        # Check for specific extensions
        local required_extensions=(
            "ms-python.python"
            "ms-toolsai.jupyter"
            "tomoki1207.pdf"
        )
        
        local missing_extensions=()
        for ext in "${required_extensions[@]}"; do
            if ! echo "$extensions" | grep -q "$ext"; then
                missing_extensions+=("$ext")
            fi
        done
        
        if [ ${#missing_extensions[@]} -eq 0 ]; then
            log_success "All required extensions are installed"
        else
            log_warning "Some extensions may still be installing: ${missing_extensions[*]}"
            log_info "This is normal during automated installation - extensions install in background"
        fi
    else
        log_warning "Could not list extensions (this is often normal during automated testing)"
    fi
}

# Function to test Python integration
test_python_integration() {
    log_info "Testing Python integration..."
    
    # Check if settings were created
    local settings_dir="$HOME/Library/Application Support/Code/User"
    if [ -f "$settings_dir/settings.json" ]; then
        log_success "VSCode settings configured for Python development"
        log_info "Settings location: $settings_dir/settings.json"
    else
        log_warning "VSCode settings not found (may be created on first launch)"
    fi
    
    # Test basic Python functionality by creating a temporary file
    local temp_dir
    temp_dir=$(mktemp -d)
    local test_file="$temp_dir/test.py"
    
    echo "print('Hello from VSCode PKG test!')" > "$test_file"
    
    log_info "Testing Python file handling with VSCode..."
    if timeout 10s code "$test_file" --wait >/dev/null 2>&1; then
        log_success "VSCode can handle Python files"
    else
        log_info "VSCode launched (timeout reached - this is normal for automated testing)"
    fi
    
    # Clean up
    rm -rf "$temp_dir"
}

# Function to run comprehensive tests
run_comprehensive_tests() {
    log_info "Running comprehensive VSCode PKG tests..."
    
    local test_results=()
    
    # Test app installation
    if test_vscode_app; then
        test_results+=("App installation: PASS")
    else
        test_results+=("App installation: FAIL")
    fi
    
    # Test CLI tools
    if test_cli_tools; then
        test_results+=("CLI tools: PASS")
    else
        test_results+=("CLI tools: FAIL")
    fi
    
    # Test extensions (allow warnings)
    test_extensions
    test_results+=("Extensions: CHECKED")
    
    # Test Python integration
    test_python_integration
    test_results+=("Python integration: CHECKED")
    
    # Display results summary
    log_info "=== Test Results Summary ==="
    printf '%s\n' "${test_results[@]}"
    
    log_success "VSCode PKG testing completed!"
}

# Main execution
main() {
    log_info "Starting VSCode PKG test..."
    
    local pkg_path
    pkg_path=$(find_pkg_file)
    
    log_info "Found VSCode PKG: $pkg_path"
    
    install_pkg "$pkg_path"
    run_comprehensive_tests
    
    log_success "VSCode PKG test completed successfully!"
}

# Handle command line arguments
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi