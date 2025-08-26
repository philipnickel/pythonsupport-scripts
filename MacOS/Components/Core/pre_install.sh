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

# Load Piwik utility for analytics
if curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared/piwik_utility.sh" -o /tmp/piwik_utility.sh 2>/dev/null && source /tmp/piwik_utility.sh 2>/dev/null; then
    # Remove existing Piwik choice file to ensure fresh consent prompt
    rm -f /tmp/piwik_analytics_choice
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
    elif [[ "${CLI_MODE:-}" == "true" ]]; then
        echo "CLI Mode: You have an existing Anaconda/miniconda/miniforge installation."
        echo "Uninstall existing version and continue? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Installation aborted by user."
            exit 1
        fi
        response="yes"
    else
        echo "GUI Mode: DTU Python Support only works with Miniforge."
        
        # Use macOS native dialog for user interaction with authentication
        response=$(osascript -e 'tell app "System Events" to display dialog "DTU Python Support detected an existing conda installation.\n\nYou have an existing Anaconda/miniconda/miniforge installation.\n\nDo you want to uninstall the existing version and continue with the installation?\n\nYou will be prompted for administrator privileges to complete the uninstallation.\n\nNote: A native macOS popup will appear asking for your password." buttons {"Cancel", "Uninstall & Continue"} default button "Uninstall & Continue" with icon caution')
        
        # Check if user cancelled or closed the dialog
        if [[ $? -ne 0 ]] || [[ -z "$response" ]] || [[ "$response" == *"Cancel"* ]]; then
            echo "Installation aborted by user."
            exit 1
        fi
        
        # Set response to "yes" if user clicked "Uninstall & Continue"
        if [[ "$response" == *"Uninstall & Continue"* ]]; then
            response="yes"
        fi
    fi
    
    # Execute uninstall script for all modes when user agrees
    if [[ "$response" == "yes" ]]; then
        echo "Uninstalling existing conda..."
        curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Core/uninstall_conda.sh" | bash
        
        if [ $? -eq 0 ]; then
            echo "Conda uninstallation completed successfully"
        else
            echo "Conda uninstallation failed"
            exit 1
        fi
        
        echo "Continuing with Miniforge installation..."
    fi
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