#!/bin/bash
# @doc
# @name: Pre-Installation Check Script
# @description: Checks for existing installations and system requirements before running the main installer
# @category: Core
# @usage: ./pre_install.sh
# @requirements: macOS system
# @notes: Should be run before any installation process to assess system state
# @/doc

# Set up install log for this script
[ -z "$INSTALL_LOG" ] && INSTALL_LOG="/tmp/dtu_install_$(date +%Y%m%d_%H%M%S).log"

# Start piwik logging if available
if command -v piwik_log_event >/dev/null 2>&1; then
    piwik_log_event "installation" "start" "DTU Python pre-installation check started"
fi

echo "DTU Python Support - Pre-Installation Check"
echo "============================================="
echo ""

# Export flags for main installer to use
export SKIP_PYTHON_INSTALL=false
export SKIP_VSCODE_INSTALL=false
export NEEDS_CONDA_UNINSTALL=false
export CONDA_UNINSTALL_TYPE=""

# Check for existing conda installations
echo "Checking for existing conda installations..."

# Check for Miniforge (preferred)
if [ -d "$HOME/miniforge3" ] && [ -x "$HOME/miniforge3/bin/conda" ]; then
    echo "✓ Miniforge found at $HOME/miniforge3"
    echo "  → Python installation will be skipped, but packages will still be set up"
    export SKIP_PYTHON_INSTALL=true
    
    # Log to piwik
    if command -v piwik_log_event >/dev/null 2>&1; then
        piwik_log_event "pre_check" "miniforge_found" "Miniforge installation detected"
    fi
    
# Check for Anaconda/Miniconda (needs user decision)
elif [ -d "$HOME/anaconda3" ] || [ -d "$HOME/miniconda3" ] || [ -d "/opt/anaconda3" ] || [ -d "/opt/miniconda3" ]; then
    if [ -d "$HOME/anaconda3" ] || [ -d "/opt/anaconda3" ]; then
        CONDA_TYPE="Anaconda"
        CONDA_PATH=$([ -d "$HOME/anaconda3" ] && echo "$HOME/anaconda3" || echo "/opt/anaconda3")
    else
        CONDA_TYPE="Miniconda"
        CONDA_PATH=$([ -d "$HOME/miniconda3" ] && echo "$HOME/miniconda3" || echo "/opt/miniconda3")
    fi
    
    echo "⚠  $CONDA_TYPE installation found at $CONDA_PATH"
    echo ""
    echo "DTU recommends using Miniforge instead of $CONDA_TYPE for better compatibility."
    echo "Would you like to uninstall $CONDA_TYPE and install Miniforge?"
    echo ""
    read -p "Uninstall $CONDA_TYPE? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "→ $CONDA_TYPE will be uninstalled before installing Miniforge"
        export NEEDS_CONDA_UNINSTALL=true
        export CONDA_UNINSTALL_TYPE="$CONDA_TYPE"
        export SKIP_PYTHON_INSTALL=false
        
        # Log to piwik
        if command -v piwik_log_event >/dev/null 2>&1; then
            piwik_log_event "pre_check" "conda_uninstall_requested" "$CONDA_TYPE uninstall requested by user"
        fi
    else
        echo "→ Keeping existing $CONDA_TYPE installation"
        echo "→ Python installation will be skipped"
        export SKIP_PYTHON_INSTALL=true
        
        # Log to piwik
        if command -v piwik_log_event >/dev/null 2>&1; then
            piwik_log_event "pre_check" "conda_kept" "$CONDA_TYPE installation kept by user"
        fi
    fi
    
# No conda installation found
else
    echo "→ No conda installation found, Miniforge will be installed"
    export SKIP_PYTHON_INSTALL=false
    
    # Log to piwik
    if command -v piwik_log_event >/dev/null 2>&1; then
        piwik_log_event "pre_check" "no_conda" "No conda installation found"
    fi
fi

echo ""

# Check for existing VS Code installation
echo "Checking for Visual Studio Code..."

if command -v code >/dev/null 2>&1; then
    VSCODE_VERSION=$(code --version 2>/dev/null | head -1)
    echo "✓ VS Code found (version: $VSCODE_VERSION)"
    echo "  → VS Code installation will be skipped"
    export SKIP_VSCODE_INSTALL=true
    
    # Log to piwik
    if command -v piwik_log_event >/dev/null 2>&1; then
        piwik_log_event "pre_check" "vscode_found" "VS Code installation detected: $VSCODE_VERSION"
    fi
    
elif [ -d "/Applications/Visual Studio Code.app" ]; then
    echo "✓ VS Code found at /Applications/Visual Studio Code.app"
    echo "  → VS Code installation will be skipped, but 'code' command may need setup"
    export SKIP_VSCODE_INSTALL=true
    
    # Log to piwik
    if command -v piwik_log_event >/dev/null 2>&1; then
        piwik_log_event "pre_check" "vscode_found_no_cli" "VS Code app found but CLI not in PATH"
    fi
    
else
    echo "→ VS Code not found, it will be installed"
    export SKIP_VSCODE_INSTALL=false
    
    # Log to piwik
    if command -v piwik_log_event >/dev/null 2>&1; then
        piwik_log_event "pre_check" "no_vscode" "No VS Code installation found"
    fi
fi

echo ""

# Summary
echo "Pre-installation Summary:"
echo "========================="
if [ "$SKIP_PYTHON_INSTALL" = true ]; then
    echo "• Python: Skip installation (existing conda found)"
else
    echo "• Python: Will install Miniforge"
fi

if [ "$NEEDS_CONDA_UNINSTALL" = true ]; then
    echo "• Conda: Will uninstall $CONDA_UNINSTALL_TYPE first"
fi

if [ "$SKIP_VSCODE_INSTALL" = true ]; then
    echo "• VS Code: Skip installation (already installed)"
else
    echo "• VS Code: Will install"
fi

echo ""
echo "Proceeding with installation..."

# Export findings for other scripts to use
cat > /tmp/dtu_pre_install_flags.env << EOF
# DTU Pre-Installation Flags
# Generated: $(date)

SKIP_PYTHON_INSTALL=$SKIP_PYTHON_INSTALL
SKIP_VSCODE_INSTALL=$SKIP_VSCODE_INSTALL
NEEDS_CONDA_UNINSTALL=$NEEDS_CONDA_UNINSTALL
CONDA_UNINSTALL_TYPE="$CONDA_UNINSTALL_TYPE"
EOF

# Log completion to piwik
if command -v piwik_log_event >/dev/null 2>&1; then
    piwik_log_event "pre_check" "complete" "Pre-installation check completed"
fi

exit 0