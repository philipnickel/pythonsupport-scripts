#!/bin/bash

# Set default values for REMOTE_PS and BRANCH_PS if not provided
REMOTE_PS=${REMOTE_PS:-"dtudk/pythonsupport-scripts"}
BRANCH_PS=${BRANCH_PS:-"main"}

echo "DTU Python Support - Automated MacOS Installation"
echo "======================================="
echo "Repository: $REMOTE_PS"
echo "Branch: $BRANCH_PS"
echo ""

# Set up minimal logging
INSTALL_LOG="/tmp/dtu_install_$(date +%Y%m%d_%H%M%S).log"
export INSTALL_LOG
export REMOTE_PS
export BRANCH_PS

echo "=== DTU Python Support Installation Log ===" > "$INSTALL_LOG"
echo "Started: $(date)" >> "$INSTALL_LOG"
echo "Repository: $REMOTE_PS" >> "$INSTALL_LOG"
echo "Branch: $BRANCH_PS" >> "$INSTALL_LOG"

# === PHASE 1: PRE-INSTALLATION CHECK ===
echo "Phase 1: Pre-Installation System Check"
echo "======================================="
/bin/bash -c "REMOTE_PS='${REMOTE_PS}' BRANCH_PS='${BRANCH_PS}' $(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Core/pre_install.sh)"

# Load pre-installation flags
if [ -f /tmp/dtu_pre_install_flags.env ]; then
    source /tmp/dtu_pre_install_flags.env
fi

# Echo findings
echo ""
echo "Phase 1 Findings:"
echo "-----------------"
if [ "$SKIP_VSCODE_INSTALL" = true ]; then
    echo "• VS Code: Already installed - will skip"
else
    echo "• VS Code: Not found - will install"
fi
echo ""

# === PHASE 2: MAIN INSTALLATION ===
echo "Phase 2: Main Installation Process"
echo "=================================="


# Install Python with Miniforge  
echo "Installing Python with Miniforge..."
/bin/bash -c "REMOTE_PS='${REMOTE_PS}' BRANCH_PS='${BRANCH_PS}' $(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Python/install.sh)"

# Setup Python environment and packages
echo "Setting up Python environment and packages..."
/bin/bash -c "REMOTE_PS='${REMOTE_PS}' BRANCH_PS='${BRANCH_PS}' $(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Python/first_year_setup.sh)"

# Install Visual Studio Code (conditionally)
if [ "$SKIP_VSCODE_INSTALL" = true ]; then
    echo "Skipping VS Code installation (already installed)"
else
    echo "Installing Visual Studio Code..."
    /bin/bash -c "REMOTE_PS='${REMOTE_PS}' BRANCH_PS='${BRANCH_PS}' $(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/VSC/install.sh)"
fi

# === PHASE 3: POST-INSTALLATION VERIFICATION ===
echo "Phase 3: Post-Installation Verification"
echo "========================================"

/bin/bash -c "REMOTE_PS='${REMOTE_PS}' BRANCH_PS='${BRANCH_PS}' $(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Core/post_install.sh)" 
echo ""
echo "DTU Python Support Installation Complete!"
echo "================================="
echo "Next steps:"
echo "• See the Installation HTML report for details"
echo "Need help? Visit: https://pythonsupport.dtu.dk"
