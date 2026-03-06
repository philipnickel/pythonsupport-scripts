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
REMOTE_PS=${REMOTE_PS:-"dtudk/pythonsupport-scripts"}
BRANCH_PS=${BRANCH_PS:-"main"}

# Load Piwik utility for analytics
#if curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared/piwik_utility.sh" -o /tmp/piwik_utility.sh 2>/dev/null && source /tmp/piwik_utility.sh 2>/dev/null; then
#    PIWIK_LOADED=true
#else
#    PIWIK_LOADED=false
#fi

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
        if [[ "${PIS_ENV:-}" == "CI" ]]; then
            # CI mode - no sudo needed, use user directory
            mkdir -p "$HOME/bin" 2>/dev/null || true
            ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" "$HOME/bin/code" 2>/dev/null || true
            export PATH="$HOME/bin:$PATH"
        elif [[ "${CLI_MODE:-}" == "true" ]]; then
            # CLI mode - use sudo directly
            echo "Please enter the password to your computer to continue (you will not be able to see what you type)"
            sudo ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code 2>/dev/null || true
        else
            # GUI mode - use osascript for native authentication
            if osascript -e "do shell script \"ln -sf '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code' /usr/local/bin/code\" with prompt \"DTU Python Support needs administrator privileges to create a VS Code command line shortcut.\" with administrator privileges" 2>/dev/null; then
                echo "VS Code CLI symlink created successfully"
            else
                echo "User cancelled authentication or symlink creation failed"
                echo "Installation aborted by user."
                exit 1
            fi
        fi
        echo "Created symlink for VS Code CLI"
    fi
else
    echo "VS Code not found, installing..."
    
    # Detect architecture for proper download
    ARCH=$(uname -m)
    echo "Detected architecture: $ARCH"
    if [[ "$ARCH" == "arm64" ]]; then
        VSCODE_URL="https://update.code.visualstudio.com/latest/darwin-arm64/stable"
    else
        VSCODE_URL="https://update.code.visualstudio.com/latest/darwin/stable"
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
        # [ "$PIWIK_LOADED" = true ] && piwik_log 31  # VS Code Installation fail
        # exit 1
    fi
    
    # [ "$PIWIK_LOADED" = true ] && piwik_log 30  # VS Code Installation success
    
    # Clean up
    rm -f /tmp/VSCode.zip
    
    echo "Creating VS Code CLI symlink..."
    # Create symlink for 'code' command
    if [[ "${PIS_ENV:-}" == "CI" ]]; then
        # CI mode - no sudo needed, use user directory
        mkdir -p "$HOME/bin" 2>/dev/null || true
        ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" "$HOME/bin/code" 2>/dev/null || true
        export PATH="$HOME/bin:$PATH"
    elif [[ "${CLI_MODE:-}" == "true" ]]; then
        # CLI mode - use sudo directly
        echo "Please enter the password to your computer to continue (you will not be able to see what you type)"
        sudo mkdir -p /usr/local/bin 2>/dev/null || true
        sudo ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code 2>/dev/null || true
    else
        # GUI mode - use osascript for native authentication
        if osascript -e "do shell script \"mkdir -p /usr/local/bin && ln -sf '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code' /usr/local/bin/code\" with prompt \"DTU Python Support needs administrator privileges to set up VS Code command line tools.\" with administrator privileges" 2>/dev/null; then
            echo "VS Code CLI tools set up successfully"
        else
            echo "User cancelled authentication or VS Code CLI setup failed"
            echo "Installation aborted by user."
            exit 1
        fi
    fi
    
    # Add to PATH for this session (handle both CI and non-CI modes)
    if [[ "${PIS_ENV:-}" == "CI" ]]; then
        export PATH="$HOME/bin:$PATH"
    else
        export PATH="/usr/local/bin:$PATH"
    fi
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

# Ensure PATH is updated for CI mode
if [[ "${PIS_ENV:-}" == "CI" ]]; then
    export PATH="$HOME/bin:$PATH"
    echo "CI mode: Updated PATH to include $HOME/bin"
fi

if ! command -v code >/dev/null; then
  echo "Code command not found in PATH, checking bundled location..."
  if [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
    CODE_CLI="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    echo "Using bundled VS Code CLI: $CODE_CLI"
  else
    echo "WARNING: VS Code CLI not found at bundled location"
    echo "Checking if VS Code app exists..."
    ls -la "/Applications/Visual Studio Code.app/" 2>/dev/null || echo "VS Code app not found"
    echo "VS Code CLI not available for extension installation"
    CODE_CLI=""
  fi
else
  CODE_CLI="code"
  echo "Using VS Code CLI from PATH: $(which code)"
fi

# Test VS Code CLI before installing extensions
echo "Testing VS Code CLI..."
if ! "$CODE_CLI" --version; then
    echo "WARNING: VS Code CLI test failed, but continuing with installation"
    echo "VS Code CLI may not be available for extension installation"
else
    echo "VS Code CLI test passed"
fi

# Install essential extensions
echo "Installing VS Code extensions..."

# Define extensions to install
extensions=(
  "ms-python.python"
  "ms-toolsai.jupyter"
  #"tomoki1207.pdf"
)

# Install extensions one by one with error handling
failed_extensions=()
if [[ -z "$CODE_CLI" ]]; then
    echo "VS Code CLI not available, skipping extension installation"
    failed_extensions=("${extensions[@]}")
else
    for extension in "${extensions[@]}"; do
        echo "Installing $extension..."
        if "$CODE_CLI" --install-extension "$extension" --force; then
            echo "Successfully installed $extension"
        else
            echo "Failed to install $extension"
            failed_extensions+=("$extension")
        fi
    done
fi

# Report results
if [ ${#failed_extensions[@]} -eq 0 ]; then
    echo "All VS Code extensions installed successfully"
    # [ "$PIWIK_LOADED" = true ] && piwik_log 40  # VS Code Extensions success
elif [ ${#failed_extensions[@]} -eq ${#extensions[@]} ]; then
    echo "All extension installations failed, but continuing installation"
    echo "Extensions can be installed manually later"
    # [ "$PIWIK_LOADED" = true ] && piwik_log 41  # VS Code Extensions fail
else
    echo "Some extensions failed to install: ${failed_extensions[*]}"
    echo "Installation will continue (extensions can be installed manually later)"
    # [ "$PIWIK_LOADED" = true ] && piwik_log 40  # VS Code Extensions success (partial)
fi

echo "VS Code extensions installation complete"
echo "Installed extensions:"
"$CODE_CLI" --list-extensions

