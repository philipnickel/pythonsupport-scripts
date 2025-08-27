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
#if curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared/piwik_utility.sh" -o /tmp/piwik_utility.sh 2>/dev/null && source /tmp/piwik_utility.sh 2>/dev/null; then
#    # Remove existing Piwik choice file to ensure fresh consent prompt
#    rm -f /tmp/piwik_analytics_choice
#    piwik_log 1  # Installation Started
#fi

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

# Function to find all conda installations
find_all_conda_installations() {
    local installations=()
    
    # Check if conda command is available and get its base
    if command -v conda >/dev/null 2>&1; then
        local conda_base=$(conda info --base 2>/dev/null || echo "")
        if [ -n "$conda_base" ] && [ -d "$conda_base" ]; then
            installations+=("$conda_base")
        fi
    fi
    
    # Check common installation locations
    local common_paths=(
        "$HOME/miniforge3"
        "$HOME/miniconda3"
        "$HOME/anaconda3"
        "/opt/miniforge3"
        "/opt/miniconda3"
        "/opt/anaconda3"
        "/usr/local/miniforge3"
        "/usr/local/miniconda3"
        "/usr/local/anaconda3"
        "/Applications/miniforge3"
        "/Applications/miniconda3"
        "/Applications/anaconda3"
    )
    
    for path in "${common_paths[@]}"; do
        if [ -d "$path" ] && [ -x "$path/bin/conda" ]; then
            # Check if this path is not already in the list
            local found=false
            for existing in "${installations[@]}"; do
                if [[ "$existing" == "$path" ]]; then
                    found=true
                    break
                fi
            done
            if [ "$found" = false ]; then
                installations+=("$path")
            fi
        fi
    done
    
    echo "${installations[@]}"
}

# Find all conda installations
echo "Scanning for all conda installations..."
all_conda_installations=($(find_all_conda_installations))

if [ ${#all_conda_installations[@]} -gt 0 ]; then
    CONDA_FOUND=true
    echo "Found ${#all_conda_installations[@]} conda installation(s):"
    for i in "${!all_conda_installations[@]}"; do
        conda_path="${all_conda_installations[$i]}"
        conda_type="Conda"
        if echo "$conda_path" | grep -q "miniforge"; then
            conda_type="Miniforge"
        elif echo "$conda_path" | grep -q "miniconda"; then
            conda_type="Miniconda"
        elif echo "$conda_path" | grep -q "anaconda"; then
            conda_type="Anaconda"
        fi
        echo "  $((i+1)). $conda_type at: $conda_path"
    done
    
    # Set the first installation as the primary one for backward compatibility
    CONDA_PATH="${all_conda_installations[0]}"
    if echo "$CONDA_PATH" | grep -q "miniforge"; then
        CONDA_TYPE="Miniforge"
    elif echo "$CONDA_PATH" | grep -q "miniconda"; then
        CONDA_TYPE="Miniconda"
    elif echo "$CONDA_PATH" | grep -q "anaconda"; then
        CONDA_TYPE="Anaconda"
    else
        CONDA_TYPE="Conda"
    fi
else
    CONDA_FOUND=false
fi



# Handle conda detection results
if [ "$CONDA_FOUND" = true ]; then
    echo ""
    echo "The uninstaller will remove ALL conda installations listed above."
    
    if [[ "${PIS_ENV:-}" == "CI" ]]; then
        echo "Running in automated mode - automatically uninstalling existing conda..."
        response="yes"
    elif [[ "${CLI_MODE:-}" == "true" ]]; then
        echo "CLI Mode: You have existing Anaconda/miniconda/miniforge installation(s)."
        echo "The uninstaller will scan for and remove ALL conda installations found on your system."
        echo "Uninstall all existing conda installations and continue? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Installation aborted by user."
            exit 1
        fi
        response="yes"
    else
        echo "GUI Mode: DTU Python Support only works with Miniforge."
        
        # Use macOS native dialog for user interaction with authentication
        response=$(osascript -e 'tell app "System Events" to display dialog "DTU Python Support detected existing conda installation(s).\n\nYou have existing Anaconda/miniconda/miniforge installation(s).\n\nThe uninstaller will scan for and remove ALL conda installations found on your system.\n\nDo you want to uninstall all existing conda installations and continue with the installation?\n\nYou will be prompted for administrator privileges to complete the uninstallation.\n\nNote: A native macOS popup will appear asking for your password." buttons {"Cancel", "Uninstall All & Continue"} default button "Uninstall All & Continue" with icon caution')
        
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
        echo "Uninstalling existing conda installations (running multiple passes to ensure complete removal)..."
        
        # Run the uninstall script multiple times to catch all installations
        # Download and run the uninstall script
        curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Core/uninstall_conda.sh" > /tmp/uninstall_conda.sh
        for pass in {1..4}; do
            echo "Pass $pass of 4: Checking for remaining conda installations..."
            
            bash /tmp/uninstall_conda.sh
            
            if [ $? -eq 0 ]; then
                echo "Pass $pass completed successfully"
            else
                echo "Pass $pass failed or was cancelled"
                rm -f /tmp/uninstall_conda.sh
                exit 1
            fi
        done
        
        rm -f /tmp/uninstall_conda.sh
        echo "All conda uninstallation passes completed successfully"
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
