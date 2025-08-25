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
export SKIP_VSCODE_INSTALL=false

# Check for Miniforge specifically
if [ -d "$HOME/miniforge3" ] && [ -x "$HOME/miniforge3/bin/conda" ]; then
    echo "• Miniforge found"
    
    # Check Python version and packages
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
        if echo "$PYTHON_VERSION" | grep -q "^3\.11\."; then
            echo "  ✓ Python 3.11 ($PYTHON_VERSION)"
            
            # Check for DTU packages
            packages=("dtumathtools" "pandas" "scipy" "statsmodels" "uncertainties")
            all_found=true
            for package in "${packages[@]}"; do
                if ! python3 -c "import $package" 2>/dev/null; then
                    all_found=false
                    break
                fi
            done
            
            if [ "$all_found" = true ]; then
                echo "  ✓ All DTU packages found"
                echo "Everything is already properly installed!"
                echo "Cancel installation? (y/n)"
                read -r response
                if [[ "$response" =~ ^[Yy]$ ]]; then
                    echo "Installation cancelled - system already configured"
                    exit 0
                fi
                echo "• Continuing with installation anyway..."
            else
                echo "  ⚠ Some DTU packages missing"
                echo "Continue with installation to add missing packages? (y/n)"
                read -r response
                if [[ ! "$response" =~ ^[Yy]$ ]]; then
                    echo "Installation aborted"
                    exit 1
                fi
            fi
        else
            echo "  ⚠ Wrong Python version ($PYTHON_VERSION), need 3.11"
            echo "Continue with installation to fix Python version? (y/n)"
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                echo "Installation aborted"
                exit 1
            fi
        fi
    else
        echo "  ⚠ Python not found in PATH"
        echo "Continue with installation to fix Python setup? (y/n)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Installation aborted"
            exit 1
        fi
    fi

# Check for other conda installations
elif [ -d "$HOME/anaconda3" ] || [ -d "$HOME/miniconda3" ] || [ -d "/opt/anaconda3" ] || [ -d "/opt/miniconda3" ] || command -v conda >/dev/null 2>&1; then
    echo "• Other conda installation detected"
    echo "For a clean DTU installation, please uninstall existing conda first."
    echo "Continue anyway? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Installation aborted. Please uninstall conda and try again."
        exit 1
    fi
    echo "• Continuing with existing conda..."
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