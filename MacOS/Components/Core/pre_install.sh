#!/bin/bash
# @doc
# @name: Pre-Installation Check Script
# @description: Simple checks for existing installations
# @category: Core
# @usage: ./pre_install.sh
# @requirements: macOS system
# @/doc

# Load configuration
source <(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/config.sh")

# Start piwik logging if available
if command -v piwik_log_event >/dev/null 2>&1; then
    piwik_log_event "installation" "start" "DTU Python installation started"
fi

echo "Checking existing installations..."

# Export flags for main installer
export SKIP_VSCODE_INSTALL=false

# Check for Miniforge specifically
if [ -d "$MINIFORGE_PATH" ] && [ -x "$MINIFORGE_PATH/bin/conda" ]; then
    echo "• Miniforge found"
    echo "Everything appears to be already installed!"
    echo "Cancel installation? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Installation cancelled - Miniforge already present"
        exit 0
    fi
    echo "• Continuing with installation anyway..."

# Check for other conda installations  
elif [ -d "$HOME/anaconda3" ] || [ -d "$HOME/miniconda3" ] || [ -d "/opt/anaconda3" ] || [ -d "/opt/miniconda3" ] || command -v conda >/dev/null 2>&1; then
    echo "• Other conda installation detected"
    echo ""
    echo "For best results, DTU recommends uninstalling existing conda first."
    echo "What would you like to do?"
    echo "1) Automatically uninstall existing conda and continue"
    echo "2) Continue with existing conda (not recommended)"
    echo "3) Abort installation"
    echo ""
    read -p "Choose option (1/2/3): " -r response
    
    case $response in
        1)
            echo "• Running conda uninstall script..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Core/uninstall_conda.sh)"
            if [ $? -eq 0 ]; then
                echo "• Conda uninstalled successfully, continuing with installation..."
            else
                echo "• Conda uninstall failed, aborting installation"
                exit 1
            fi
            ;;
        2)
            echo "• Continuing with existing conda installation..."
            ;;
        3|*)
            echo "Installation aborted."
            exit 1
            ;;
    esac
fi

# Check for VS Code
if command -v code >/dev/null 2>&1 || [ -d "/Applications/Visual Studio Code.app" ]; then
    echo "• VS Code found - skipping installation"
    export SKIP_VSCODE_INSTALL=true
fi

# Save flags
cat > /tmp/dtu_pre_install_flags.env << EOF
SKIP_VSCODE_INSTALL=$SKIP_VSCODE_INSTALL
EOF

echo "Pre-check complete"