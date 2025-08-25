#!/bin/bash
# @doc
# @name: Pre-Installation Check Script
# @description: Simple checks for existing installations
# @category: Core
# @usage: ./pre_install.sh
# @requirements: macOS system
# @/doc

# Start piwik logging if available
if command -v piwik_log_event >/dev/null 2>&1; then
    piwik_log_event "installation" "start" "DTU Python installation started"
fi

echo "Checking existing installations..."

# Export flags for main installer
export SKIP_PYTHON_INSTALL=false
export SKIP_VSCODE_INSTALL=false

# Check for Miniforge
if [ -d "$HOME/miniforge3" ] && [ -x "$HOME/miniforge3/bin/conda" ]; then
    echo "• Miniforge found - skipping Python installation"
    export SKIP_PYTHON_INSTALL=true
fi

# Check for Anaconda/Miniconda and prompt
if [ -d "$HOME/anaconda3" ] || [ -d "$HOME/miniconda3" ]; then
    CONDA_TYPE="Anaconda/Miniconda"
    echo "• $CONDA_TYPE found"
    echo "DTU recommends Miniforge. Uninstall $CONDA_TYPE first? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Please uninstall $CONDA_TYPE manually and rerun this installer"
        exit 1
    else
        echo "• Keeping existing installation - skipping Python"
        export SKIP_PYTHON_INSTALL=true
    fi
fi

# Check for VS Code
if command -v code >/dev/null 2>&1 || [ -d "/Applications/Visual Studio Code.app" ]; then
    echo "• VS Code found - skipping VS Code installation"
    export SKIP_VSCODE_INSTALL=true
fi

# Save flags
cat > /tmp/dtu_pre_install_flags.env << EOF
SKIP_PYTHON_INSTALL=$SKIP_PYTHON_INSTALL
SKIP_VSCODE_INSTALL=$SKIP_VSCODE_INSTALL
EOF

echo "Pre-check complete"