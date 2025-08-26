#!/bin/bash
# @doc
# @name: VSCode Installation (Direct Download)
# @description: Installs Visual Studio Code on macOS without Homebrew dependency
# @category: IDE
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/VSC/install.sh)"
# @requirements: macOS system, internet connection
# @notes: Uses master utility system for consistent error handling and logging. Downloads and installs VSCode directly from Microsoft
# @/doc

# VS Code installation script - no external config dependencies

# Set up install log for this script  
[ -z "$INSTALL_LOG" ] && INSTALL_LOG="/tmp/dtu_install_$(date +%Y%m%d_%H%M%S).log"

echo "VS Code Installation starting..."
echo "REMOTE_PS: ${REMOTE_PS:-not set}"
echo "BRANCH_PS: ${BRANCH_PS:-not set}"

# Check if VSCode is already installed
echo "Checking for existing VS Code installation..."
if command -v code > /dev/null 2>&1; then
    vscode_path=$(which code)
    echo "VS Code CLI found at: $vscode_path"
elif [ -d "/Applications/Visual Studio Code.app" ]; then
    vscode_path="/Applications/Visual Studio Code.app"
    echo "VS Code app found, setting up CLI symlink..."
    # Add to PATH if not already there
    if ! command -v code > /dev/null 2>&1; then
        sudo ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code 2>/dev/null || true
        echo "Created symlink for VS Code CLI"
    fi
else
    echo "VS Code not found, installing..."
    
    # Detect architecture for proper download
    ARCH=$(uname -m)
    echo "Detected architecture: $ARCH"
    if [[ "$ARCH" == "arm64" ]]; then
        VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=darwin-arm64"
    else
        VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=darwin"
    fi
    
    echo "Downloading VS Code from: $VSCODE_URL"
    curl -fsSL "$VSCODE_URL" -o /tmp/VSCode.zip
    if [ $? -ne 0 ]; then 
        echo "ERROR: Failed to download VS Code"
        exit 1
    fi
    
    echo "Extracting VS Code..."
    unzip -qq /tmp/VSCode.zip -d /tmp/
    if [ $? -ne 0 ]; then 
        echo "ERROR: Failed to extract VS Code"
        exit 1
    fi
    
    echo "Installing VS Code to Applications..."
    if [ -d "/Applications/Visual Studio Code.app" ]; then
        echo "Removing existing VS Code installation..."
        rm -rf "/Applications/Visual Studio Code.app"
    fi
    
    mv "/tmp/Visual Studio Code.app" "/Applications/"
    if [ $? -ne 0 ]; then 
        echo "ERROR: Failed to move VS Code to Applications"
        exit 1
    fi
    
    # Clean up
    rm -f /tmp/VSCode.zip
    
    echo "Creating VS Code CLI symlink..."
    # Create symlink for 'code' command
    sudo mkdir -p /usr/local/bin 2>/dev/null || true
    sudo ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code 2>/dev/null || true
    
    # Add to PATH for this session
    export PATH="/usr/local/bin:$PATH"
    echo "VS Code installation complete"
fi

# Update PATH and refresh
hash -r
clear -x


# Install extensions immediately after VSCode installation
echo ""
echo "Setting up VS Code extensions..."

# Check if code CLI is available, use bundled path if needed
echo "Looking for VS Code CLI..."
if ! command -v code >/dev/null; then
  echo "Code command not found in PATH, checking bundled location..."
  if [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
    CODE_CLI="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    echo "Using bundled VS Code CLI: $CODE_CLI"
  else
    echo "ERROR: VS Code CLI not found at bundled location"
    echo "Checking if VS Code app exists..."
    ls -la "/Applications/Visual Studio Code.app/" 2>/dev/null || echo "VS Code app not found"
    exit 1
  fi
else
  CODE_CLI="code"
  echo "Using VS Code CLI from PATH: $(which code)"
fi

# Test VS Code CLI before installing extensions
echo "Testing VS Code CLI..."
if ! "$CODE_CLI" --version; then
    echo "ERROR: VS Code CLI test failed"
    exit 1
fi

# Install essential extensions
echo "Installing VS Code extensions..."

# Define extensions to install
extensions=(
    "ms-python.python"
    "ms-toolsai.jupyter" 
    "tomoki1207.pdf"
)

# Install extensions one by one with error handling
failed_extensions=()
for extension in "${extensions[@]}"; do
    echo "Installing $extension..."
    if "$CODE_CLI" --install-extension "$extension" --force; then
        echo "Successfully installed $extension"
    else
        echo "Failed to install $extension"
        failed_extensions+=("$extension")
    fi
done

# Report results
if [ ${#failed_extensions[@]} -eq 0 ]; then
    echo "All VS Code extensions installed successfully"
elif [ ${#failed_extensions[@]} -eq ${#extensions[@]} ]; then
    echo "All extension installations failed"
    exit 1
else
    echo "Some extensions failed to install: ${failed_extensions[*]}"
    echo "Installation will continue (extensions can be installed manually later)"
fi

echo "VS Code extensions installation complete"
echo "Installed extensions:"
"$CODE_CLI" --list-extensions

