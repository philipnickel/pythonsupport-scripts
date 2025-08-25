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

log "Installing Visual Studio Code"

# Check if VSCode is already installed
log "Checking for existing Visual Studio Code installation..."
if command -v code > /dev/null 2>&1; then
    vscode_path=$(which code)
    log "Visual Studio Code is already installed at: $vscode_path"
elif [ -d "/Applications/Visual Studio Code.app" ]; then
    vscode_path="/Applications/Visual Studio Code.app"
    log "Visual Studio Code is already installed at: $vscode_path"
    # Add to PATH if not already there
    if ! command -v code > /dev/null 2>&1; then
        log "Adding VSCode command line tools to PATH..."
        sudo ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code 2>/dev/null || true
    fi
else
    log "Visual Studio Code not found, downloading and installing..."
    
    # Detect architecture for proper download
    if [[ $(uname -m) == "arm64" ]]; then
        VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=darwin-arm64"
        ARCH="arm64"
    else
        VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=darwin"
        ARCH="x64"
    fi
    
    log "Downloading Visual Studio Code for macOS (${ARCH})..."
    curl -fsSL "$VSCODE_URL" -o /tmp/VSCode.zip
    if [ $? -ne 0 ]; then log "Failed to download Visual Studio Code"; exit 1; fi
    
    log "Extracting Visual Studio Code..."
    unzip -qq /tmp/VSCode.zip -d /tmp/
    if [ $? -ne 0 ]; then log "Failed to extract Visual Studio Code"; exit 1; fi
    
    log "Installing Visual Studio Code to Applications folder..."
    if [ -d "/Applications/Visual Studio Code.app" ]; then
        log "Removing existing installation..."
        rm -rf "/Applications/Visual Studio Code.app"
    fi
    
    mv "/tmp/Visual Studio Code.app" "/Applications/"
    if [ $? -ne 0 ]; then log "Failed to install Visual Studio Code"; exit 1; fi
    
    # Clean up
    rm -f /tmp/VSCode.zip
    
    log "Setting up command line tools..."
    # Create symlink for 'code' command
    sudo mkdir -p /usr/local/bin 2>/dev/null || true
    sudo ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code 2>/dev/null || true
    
    # Add to PATH for this session
    export PATH="/usr/local/bin:$PATH"
fi

# Update PATH and refresh
hash -r
clear -x

log "Visual Studio Code installation completed!"

# Install extensions immediately after VSCode installation
log "Installing Visual Studio Code extensions..."

# Check if code CLI is available, use bundled path if needed
if ! command -v code >/dev/null; then
  if [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
    CODE_CLI="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  else
    log "Visual Studio Code CLI not available"
    exit_message
  fi
else
  CODE_CLI="code"
fi

# Install essential extensions
log "Installing Python extension..."
"$CODE_CLI" --install-extension ms-python.python
if [ $? -ne 0 ]; then log "Failed to install Python extension"; exit 1; fi

log "Installing Jupyter extension..."
"$CODE_CLI" --install-extension ms-toolsai.jupyter
if [ $? -ne 0 ]; then log "Failed to install Jupyter extension"; exit 1; fi

log "Installing PDF extension..."
"$CODE_CLI" --install-extension tomoki1207.pdf
if [ $? -ne 0 ]; then log "Failed to install PDF extension"; exit 1; fi

log "Visual Studio Code and extensions installed successfully!"