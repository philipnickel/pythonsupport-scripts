#!/bin/bash
# @doc
# @name: Pre-Installation Check Script
# @description: Simple checks for existing installations
# @category: Core
# @usage: ./pre_install.sh
# @requirements: macOS system
# @/doc

# Set defaults if variables not provided
REMOTE_PS=${REMOTE_PS:-"dtudk/pythonsupport-scripts"}
BRANCH_PS=${BRANCH_PS:-"main"}
MINIFORGE_PATH=${MINIFORGE_PATH:-"$HOME/miniforge3"}

# Start piwik logging if available
if command -v piwik_log_event >/dev/null 2>&1; then
    piwik_log_event "installation" "start" "DTU Python installation started"
fi

echo "Checking existing installations..."

# Export flags for main installer
export SKIP_VSCODE_INSTALL=false

# Check for Miniforge specifically
if [ -d "$MINIFORGE_PATH" ] && [ -x "$MINIFORGE_PATH/bin/conda" ]; then
    echo "Miniforge found"
    echo "Everything appears to be already installed!"
    echo "Cancel installation? (y/n)"
    if [[ "${PIS_ENV:-}" == "CI" ]]; then
        echo "Running in automated mode - continuing with installation"
        response="n"
    else
        read -r response
    fi
    if [[ "$response" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        echo "Installation cancelled - Miniforge already present"
        exit 0
    fi
# Check for other conda installations  
elif [ -d "$HOME/anaconda3" ] || [ -d "$HOME/miniconda3" ] || [ -d "/opt/anaconda3" ] || [ -d "/opt/miniconda3" ] || command -v conda >/dev/null 2>&1; then
    echo "Existing conda installation detected"
    if [[ "${PIS_ENV:-}" == "CI" ]]; then
        echo "Running in automated mode - automatically uninstalling existing conda..."
    else
        echo "DTU Python Support only works with Miniforge."
        echo "Uninstall existing conda and continue? (y/n)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]([Ee][Ss])?$ ]]; then
            echo "Installation aborted."
            exit 1
        fi
    fi
    
    echo "Uninstalling existing conda..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Core/uninstall_conda.sh)"
    echo "Continuing with Miniforge installation..."
fi

# Check for VS Code
if command -v code >/dev/null 2>&1 || [ -d "/Applications/Visual Studio Code.app" ]; then
    echo "VS Code found - skipping installation"
    export SKIP_VSCODE_INSTALL=true
fi

# Save flags
cat > /tmp/dtu_pre_install_flags.env << EOF
SKIP_VSCODE_INSTALL=$SKIP_VSCODE_INSTALL
EOF

echo "Pre-check complete"