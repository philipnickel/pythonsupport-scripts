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
export SKIP_FIRST_YEAR_SETUP=false
export SKIP_VSCODE_INSTALL=false

# Check for conda installations first
if [ -d "$HOME/miniforge3" ] && [ -x "$HOME/miniforge3/bin/conda" ]; then
    echo "• Miniforge found - skipping Python installation"
    export SKIP_PYTHON_INSTALL=true
elif [ -d "$HOME/anaconda3" ] || [ -d "$HOME/miniconda3" ]; then
    echo "• Anaconda/Miniconda found"
    echo "DTU recommends Miniforge. Uninstall first? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Please uninstall manually and rerun installer"
        exit 1
    else
        echo "• Keeping existing installation - skipping Python"
        export SKIP_PYTHON_INSTALL=true
    fi
fi

# Only check Python version/packages if no conda found
if [ "$SKIP_PYTHON_INSTALL" = false ] && command -v python3 >/dev/null 2>&1; then
    PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
    if echo "$PYTHON_VERSION" | grep -q "^3\.11\."; then
        echo "• Python 3.11 found ($PYTHON_VERSION)"
        export SKIP_PYTHON_INSTALL=true
    fi
fi

# Check for DTU packages (regardless of Python install status)
if command -v python3 >/dev/null 2>&1; then
    packages=("dtumathtools" "pandas" "scipy" "statsmodels" "uncertainties")
    all_found=true
    for package in "${packages[@]}"; do
        if ! python3 -c "import $package" 2>/dev/null; then
            all_found=false
            break
        fi
    done
    
    if [ "$all_found" = true ]; then
        echo "• All DTU packages found - skipping package setup"
        export SKIP_FIRST_YEAR_SETUP=true
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
SKIP_FIRST_YEAR_SETUP=$SKIP_FIRST_YEAR_SETUP
SKIP_VSCODE_INSTALL=$SKIP_VSCODE_INSTALL
EOF

echo "Pre-check complete"