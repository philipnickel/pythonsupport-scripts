#!/bin/bash

# @doc
# @name: VSCode PKG Builder
# @description: Downloads VSCode from Microsoft and creates a macOS PKG installer with extensions
# @category: PKG Creation
# @usage: ./build_vscode_pkg.sh
# @requirements: macOS system with pkgbuild, productbuild, and internet access
# @notes: Creates a standalone VSCode PKG that installs VSCode.app, CLI tools, and Python extensions
# @/doc

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$SCRIPT_DIR/work"
BUILD_DIR="$SCRIPT_DIR/builds"
RESOURCES_DIR="$SCRIPT_DIR/resources"
VSCODE_VERSION="stable"  # Can be "stable" or specific version like "1.85.0"

# Create working directories
mkdir -p "$WORK_DIR" "$BUILD_DIR" "$RESOURCES_DIR"

log_info() {
    echo "[INFO] $*"
}

log_success() {
    echo "[SUCCESS] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

check_exit_code() {
    local msg="$1"
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "$msg (exit code: $exit_code)"
        exit $exit_code
    fi
}

cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf "$WORK_DIR"
}

trap cleanup EXIT

# Function to get VSCode download URL
get_vscode_url() {
    if [ "$VSCODE_VERSION" = "stable" ]; then
        echo "https://code.visualstudio.com/sha/download?build=stable&os=darwin-universal"
    else
        echo "https://github.com/microsoft/vscode/releases/download/${VSCODE_VERSION}/VSCode-darwin-universal-${VSCODE_VERSION}.zip"
    fi
}

# Function to download and extract VSCode
download_vscode() {
    log_info "Downloading Visual Studio Code ($VSCODE_VERSION)..."
    
    local download_url
    download_url=$(get_vscode_url)
    
    cd "$WORK_DIR"
    curl -L -o "vscode.zip" "$download_url"
    check_exit_code "Failed to download VSCode"
    
    log_info "Extracting VSCode..."
    unzip -q "vscode.zip"
    check_exit_code "Failed to extract VSCode"
    
    # Verify the app was extracted
    if [ ! -d "Visual Studio Code.app" ]; then
        log_error "VSCode app not found after extraction"
        exit 1
    fi
    
    log_success "VSCode downloaded and extracted successfully"
}

# Function to create the installation payload
create_payload() {
    log_info "Creating installation payload..."
    
    local payload_dir="$WORK_DIR/payload"
    mkdir -p "$payload_dir/Applications"
    
    # Copy VSCode app to payload
    cp -R "$WORK_DIR/Visual Studio Code.app" "$payload_dir/Applications/"
    check_exit_code "Failed to copy VSCode to payload"
    
    # Create CLI tool installation directory
    mkdir -p "$payload_dir/usr/local/bin"
    
    # Create symlink for code command
    ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" \
           "$payload_dir/usr/local/bin/code"
    
    log_success "Installation payload created"
}

# Function to create post-install script
create_postinstall_script() {
    log_info "Creating post-install script..."
    
    local scripts_dir="$WORK_DIR/scripts"
    mkdir -p "$scripts_dir"
    
    cat > "$scripts_dir/postinstall" << 'EOF'
#!/bin/bash

# Post-install script for DTU VSCode PKG
# Sets up Python extensions and configuration

set -e

USER_HOME=$(eval echo "~$USER")
USER_ID=$(id -u "$USER")
USER_GID=$(id -g "$USER")

log_info() {
    echo "[VSCode PKG] $*"
}

log_info "Starting VSCode post-install configuration..."

# Function to install extensions for a user
install_extensions_for_user() {
    local user_name="$1"
    local user_home="$2"
    local user_id="$3"
    local group_id="$4"
    
    log_info "Installing VSCode extensions for user: $user_name"
    
    # Define extensions to install
    local extensions=(
        "ms-python.python"
        "ms-toolsai.jupyter" 
        "tomoki1207.pdf"
    )
    
    # Switch to the user and install extensions
    for extension in "${extensions[@]}"; do
        log_info "Installing extension: $extension"
        if sudo -u "$user_name" /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code --install-extension "$extension" --force; then
            log_info "Successfully installed $extension"
        else
            log_info "Warning: Failed to install $extension (this is often normal during automated installation)"
        fi
    done
}

# Create default settings for Python development
create_python_settings() {
    local user_name="$1"
    local user_home="$2"
    
    log_info "Creating VSCode settings for Python development..."
    
    local settings_dir="$user_home/Library/Application Support/Code/User"
    mkdir -p "$settings_dir"
    
    # Create settings.json with Python-optimized settings
    cat > "$settings_dir/settings.json" << 'JSON_EOF'
{
    "python.defaultInterpreterPath": "/usr/bin/python3",
    "python.terminal.activateEnvironment": true,
    "jupyter.askForKernelRestart": false,
    "jupyter.interactiveWindow.creationMode": "perFile",
    "files.associations": {
        "*.py": "python"
    },
    "editor.formatOnSave": true,
    "python.formatting.provider": "autopep8",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "extensions.ignoreRecommendations": false,
    "telemetry.telemetryLevel": "off"
}
JSON_EOF
    
    # Set proper ownership
    chown -R "$user_name:$(id -gn "$user_name")" "$settings_dir" 2>/dev/null || true
    
    log_info "VSCode settings created for $user_name"
}

# Install extensions for current user if available
if [ -n "${USER:-}" ] && [ "$USER" != "root" ]; then
    install_extensions_for_user "$USER" "$USER_HOME" "$USER_ID" "$USER_GID"
    create_python_settings "$USER" "$USER_HOME"
fi

# Also try to install for the console user (the logged-in user)
CONSOLE_USER=$(stat -f "%Su" /dev/console 2>/dev/null || echo "")
if [ -n "$CONSOLE_USER" ] && [ "$CONSOLE_USER" != "root" ] && [ "$CONSOLE_USER" != "${USER:-}" ]; then
    CONSOLE_HOME=$(eval echo "~$CONSOLE_USER")
    CONSOLE_UID=$(id -u "$CONSOLE_USER")
    CONSOLE_GID=$(id -g "$CONSOLE_USER")
    
    install_extensions_for_user "$CONSOLE_USER" "$CONSOLE_HOME" "$CONSOLE_UID" "$CONSOLE_GID"
    create_python_settings "$CONSOLE_USER" "$CONSOLE_HOME"
fi

# Update system PATH for all users
log_info "Updating system PATH for VSCode CLI..."
if [ ! -f /etc/paths.d/vscode ]; then
    echo "/usr/local/bin" > /etc/paths.d/vscode
fi

log_info "VSCode post-install configuration completed successfully!"
exit 0
EOF

    # Make postinstall executable
    chmod +x "$scripts_dir/postinstall"
    
    log_success "Post-install script created"
}

# Function to build the component PKG
build_component_pkg() {
    log_info "Building VSCode component PKG..."
    
    local component_pkg="$WORK_DIR/DTU-VSCode-Component.pkg"
    
    # Build the component package
    pkgbuild \
        --root "$WORK_DIR/payload" \
        --scripts "$WORK_DIR/scripts" \
        --identifier "dk.dtu.vscode.component" \
        --version "1.0.0" \
        --install-location "/" \
        "$component_pkg"
    check_exit_code "Failed to build component PKG"
    
    log_success "Component PKG built successfully"
}

# Function to create distribution package
build_distribution_pkg() {
    log_info "Building VSCode distribution PKG..."
    
    local dist_xml="$WORK_DIR/distribution.xml"
    local final_pkg="$BUILD_DIR/DTU-VSCode-$(date +%Y%m%d-%H%M%S).pkg"
    
    # Create distribution XML
    cat > "$dist_xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>DTU Visual Studio Code</title>
    <organization>dk.dtu</organization>
    <domains enable_localSystem="true"/>
    <options customize="never" require-scripts="false" rootVolumeOnly="true"/>
    <!-- Define documents displayed at various steps -->
    <welcome file="welcome.html" mime-type="text/html"/>
    <conclusion file="conclusion.html" mime-type="text/html"/>
    <!-- List all component packages -->
    <pkg-ref id="dk.dtu.vscode.component" 
             version="1.0.0" 
             auth="root">DTU-VSCode-Component.pkg</pkg-ref>
    <!-- Define the order of installation -->
    <choices-outline>
        <line choice="default">
            <line choice="dk.dtu.vscode.component"/>
        </line>
    </choices-outline>
    <!-- Define the choice for the component -->
    <choice id="default"/>
    <choice id="dk.dtu.vscode.component" visible="false">
        <pkg-ref id="dk.dtu.vscode.component"/>
    </choice>
</installer-gui-script>
EOF

    # Create welcome message
    cat > "$WORK_DIR/welcome.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Welcome</title>
    <style>body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; }</style>
</head>
<body>
    <h2>Welcome to DTU Visual Studio Code Installer</h2>
    <p>This installer will set up Visual Studio Code with Python development extensions optimized for DTU coursework.</p>
    <p><strong>What will be installed:</strong></p>
    <ul>
        <li>Visual Studio Code application</li>
        <li>Python extension pack</li>
        <li>Jupyter notebook support</li>
        <li>PDF viewer extension</li>
        <li>CLI tools (code command)</li>
    </ul>
</body>
</html>
EOF

    # Create conclusion message
    cat > "$WORK_DIR/conclusion.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Installation Complete</title>
    <style>body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; }</style>
</head>
<body>
    <h2>Installation Complete!</h2>
    <p>Visual Studio Code has been successfully installed with Python development extensions.</p>
    <p><strong>Getting Started:</strong></p>
    <ul>
        <li>Launch Visual Studio Code from Applications folder</li>
        <li>Use <code>code</code> command in Terminal to open files/folders</li>
        <li>Python extensions are pre-configured for DTU coursework</li>
        <li>Jupyter notebooks are supported out of the box</li>
    </ul>
    <p>For support, visit the DTU Python Support documentation.</p>
</body>
</html>
EOF

    # Build final distribution package
    productbuild \
        --distribution "$dist_xml" \
        --package-path "$WORK_DIR" \
        --resources "$WORK_DIR" \
        "$final_pkg"
    check_exit_code "Failed to build distribution PKG"
    
    log_success "VSCode PKG built successfully: $final_pkg"
    
    # Show package info
    log_info "Package size: $(du -h "$final_pkg" | cut -f1)"
    log_info "Package location: $final_pkg"
}

# Main execution
main() {
    log_info "Starting DTU VSCode PKG build process..."
    
    download_vscode
    create_payload
    create_postinstall_script
    build_component_pkg
    build_distribution_pkg
    
    log_success "DTU VSCode PKG build completed successfully!"
}

# Run main function
main "$@"