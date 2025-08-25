#!/bin/bash
# @doc
# @name: VSCode Installation (Direct Download)
# @description: Installs Visual Studio Code on macOS without Homebrew dependency
# @category: IDE
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/VSC/install.sh)"
# @requirements: macOS system, internet connection
# @notes: Uses master utility system for consistent error handling and logging. Downloads and installs VSCode directly from Microsoft
# @/doc

# Load utilities with new filename to break CDN cache
eval "$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared/common.sh")"

log_info "Installing Visual Studio Code"

# Check if VSCode is already installed
log_info "Checking for existing Visual Studio Code installation..."
if command -v code > /dev/null 2>&1; then
    vscode_path=$(which code)
    log_success "Visual Studio Code is already installed at: $vscode_path"
elif [ -d "/Applications/Visual Studio Code.app" ]; then
    vscode_path="/Applications/Visual Studio Code.app"
    log_success "Visual Studio Code is already installed at: $vscode_path"
    # Add to PATH if not already there
    if ! command -v code > /dev/null 2>&1; then
        log_info "Adding VSCode command line tools to PATH..."
        sudo ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code 2>/dev/null || true
    fi
else
    log_info "Visual Studio Code not found, downloading and installing..."
    
    # Detect architecture for proper download
    if [[ $(uname -m) == "arm64" ]]; then
        VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=darwin-arm64"
        ARCH="arm64"
    else
        VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=darwin"
        ARCH="x64"
    fi
    
    log_info "Downloading Visual Studio Code for macOS (${ARCH})..."
    curl -fsSL "$VSCODE_URL" -o /tmp/VSCode.zip
    check_exit_code "Failed to download Visual Studio Code"
    
    log_info "Extracting Visual Studio Code..."
    unzip -qq /tmp/VSCode.zip -d /tmp/
    check_exit_code "Failed to extract Visual Studio Code"
    
    log_info "Installing Visual Studio Code to Applications folder..."
    if [ -d "/Applications/Visual Studio Code.app" ]; then
        log_info "Removing existing installation..."
        rm -rf "/Applications/Visual Studio Code.app"
    fi
    
    mv "/tmp/Visual Studio Code.app" "/Applications/"
    check_exit_code "Failed to install Visual Studio Code"
    
    # Clean up
    rm -f /tmp/VSCode.zip
    
    log_info "Setting up command line tools..."
    # Create symlink for 'code' command
    sudo mkdir -p /usr/local/bin 2>/dev/null || true
    sudo ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code 2>/dev/null || true
    
    # Add to PATH for this session
    export PATH="/usr/local/bin:$PATH"
fi

# Update PATH and refresh
hash -r
clear -x

log_info "Verifying Visual Studio Code installation..."
# Test if code command works
if code --version > /dev/null 2>&1; then
    log_success "Visual Studio Code installed and accessible via 'code' command"
    code --version
elif [ -d "/Applications/Visual Studio Code.app" ]; then
    log_success "Visual Studio Code installed successfully"
    log_info "Application is available in /Applications/Visual Studio Code.app"
    # Try to access the binary directly
    "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" --version 2>/dev/null || true
else
    log_error "Visual Studio Code installation verification failed"
    exit_message
fi

log_success "Visual Studio Code installation completed!"

# Install extensions immediately after VSCode installation
log_info "Installing Visual Studio Code extensions..."

# Check if code CLI is available, use bundled path if needed
if ! command -v code >/dev/null; then
  if [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
    CODE_CLI="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  else
    log_error "Visual Studio Code CLI not available"
    exit_message
  fi
else
  CODE_CLI="code"
fi

# Install essential extensions
log_info "Installing Python extension..."
"$CODE_CLI" --install-extension ms-python.python
check_exit_code "Failed to install Python extension"

log_info "Installing Jupyter extension..."
"$CODE_CLI" --install-extension ms-toolsai.jupyter
check_exit_code "Failed to install Jupyter extension"

log_info "Installing PDF extension..."
"$CODE_CLI" --install-extension tomoki1207.pdf
check_exit_code "Failed to install PDF extension"

log_success "Visual Studio Code and extensions installed successfully!"