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
if command -v piwik_log >/dev/null 2>&1; then
    piwik_log 1  # Installation Started
fi

echo "Checking existing installations..."

# Export flags for main installer
export SKIP_VSCODE_INSTALL=false

# Check for existing conda installations
CONDA_FOUND=false
CONDA_TYPE=""
CONDA_PATH=""

# Check for Miniforge specifically
if [ -d "$MINIFORGE_PATH" ] && [ -x "$MINIFORGE_PATH/bin/conda" ]; then
    CONDA_FOUND=true
    CONDA_TYPE="Miniforge"
    CONDA_PATH="$MINIFORGE_PATH"
fi

# Check for other conda installations if miniforge not found
if [ "$CONDA_FOUND" = false ]; then
    # Check various conda installation locations
    conda_paths=(
        "$HOME/miniconda3"
        "$HOME/anaconda3"
        "/opt/miniconda3"
        "/opt/anaconda3"
        "/usr/local/miniconda3"
        "/usr/local/anaconda3"
    )
    
    for conda_path in "${conda_paths[@]}"; do
        if [ -d "$conda_path" ] && [ -x "$conda_path/bin/conda" ]; then
            CONDA_FOUND=true
            CONDA_PATH="$conda_path"
            if echo "$conda_path" | grep -q "miniconda"; then
                CONDA_TYPE="Miniconda"
            elif echo "$conda_path" | grep -q "anaconda"; then
                CONDA_TYPE="Anaconda"
            else
                CONDA_TYPE="Conda"
            fi
            break
        fi
    done
fi

# Also check if conda command is in PATH
if [ "$CONDA_FOUND" = false ] && command -v conda >/dev/null 2>&1; then
    CONDA_FOUND=true
    CONDA_TYPE="Conda (in PATH)"
    CONDA_PATH=$(which conda)
fi

# Handle conda detection results
if [ "$CONDA_FOUND" = true ]; then
    echo "Existing conda installation detected: $CONDA_TYPE at $CONDA_PATH"
    
    if [[ "${PIS_ENV:-}" == "CI" ]]; then
        echo "Running in automated mode - automatically uninstalling existing conda..."
        response="yes"
    else
        echo "DTU Python Support only works with Miniforge."
        echo "Uninstall existing conda and continue?"
        
        # Use macOS native dialog for user interaction
        response=$(osascript -e 'tell app "System Events" to display dialog "DTU Python Support detected an existing conda installation.\n\nDTU Python Support only works with Miniforge.\n\nDo you want to uninstall the existing conda and continue with the installation?" buttons {"Cancel", "Uninstall & Continue"} default button "Uninstall & Continue" with icon caution')
        
        if [[ "$response" == *"Cancel"* ]]; then
            echo "Installation aborted by user."
            exit 1
        fi
        response="yes"
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