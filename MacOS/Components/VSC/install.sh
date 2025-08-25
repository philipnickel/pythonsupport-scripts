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
# Set up install log for this script
[ -z "$INSTALL_LOG" ] && INSTALL_LOG="/tmp/dtu_install_$(date +%Y%m%d_%H%M%S).log"

# Check if VSCode is already installed
if command -v code > /dev/null 2>&1; then
    vscode_path=$(which code)
elif [ -d "/Applications/Visual Studio Code.app" ]; then
    vscode_path="/Applications/Visual Studio Code.app"
    # Add to PATH if not already there
    if ! command -v code > /dev/null 2>&1; then
        sudo ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code 2>/dev/null || true
    fi
else
    
    # Detect architecture for proper download
    if [[ $(uname -m) == "arm64" ]]; then
        VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=darwin-arm64"
        ARCH="arm64"
    else
        VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=darwin"
        ARCH="x64"
    fi
    
    curl -fsSL "$VSCODE_URL" -o /tmp/VSCode.zip
    if [ $? -ne 0 ]; then exit 1; fi
    
    unzip -qq /tmp/VSCode.zip -d /tmp/
    if [ $? -ne 0 ]; then exit 1; fi
    
    if [ -d "/Applications/Visual Studio Code.app" ]; then
        rm -rf "/Applications/Visual Studio Code.app"
    fi
    
    mv "/tmp/Visual Studio Code.app" "/Applications/"
    if [ $? -ne 0 ]; then exit 1; fi
    
    # Clean up
    rm -f /tmp/VSCode.zip
    
    # Create symlink for 'code' command
    sudo mkdir -p /usr/local/bin 2>/dev/null || true
    sudo ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code 2>/dev/null || true
    
    # Add to PATH for this session
    export PATH="/usr/local/bin:$PATH"
fi

# Update PATH and refresh
hash -r
clear -x


# Install extensions immediately after VSCode installation

# Check if code CLI is available, use bundled path if needed
if ! command -v code >/dev/null; then
  if [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
    CODE_CLI="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  else
    exit_message
  fi
else
  CODE_CLI="code"
fi

# Install essential extensions
"$CODE_CLI" --install-extension ms-python.python
if [ $? -ne 0 ]; then exit 1; fi

"$CODE_CLI" --install-extension ms-toolsai.jupyter
if [ $? -ne 0 ]; then exit 1; fi

"$CODE_CLI" --install-extension tomoki1207.pdf
if [ $? -ne 0 ]; then exit 1; fi

