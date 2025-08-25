#!/bin/bash

# Set default values for REMOTE_PS and BRANCH_PS if not provided
REMOTE_PS=${REMOTE_PS:-"philipnickel/pythonsupport-scripts"}
BRANCH_PS=${BRANCH_PS:-"main"}

echo "DTU Python Support - macOS Installation"
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
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Core/pre_install.sh)"

# === PHASE 2: MAIN INSTALLATION ===
echo "Phase 2: Main Installation Process"
echo "=================================="

# Install Python with Miniforge
echo "Installing Python..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Python/install.sh)"

# Setup first year Python environment and packages
echo "Setting up Python environment..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Python/first_year_setup.sh)"

# Install Visual Studio Code
echo "Installing Visual Studio Code..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/VSC/install.sh)"

# === PHASE 3: POST-INSTALLATION VERIFICATION ===
echo "Phase 3: Post-Installation Verification"
echo "========================================"

if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Core/post_install.sh)"; then
    echo ""
    echo "🎉 DTU First Year Setup Complete!"
    echo "================================="
    echo "Your system is now ready with:"
    echo "• Python 3.11 with DTU packages"
    echo "• Visual Studio Code with Python extension"
    echo "• Comprehensive diagnostics report"
    echo ""
    echo "Next steps:"
    echo "• Open VS Code: type 'code' in Terminal"
    echo "• Start coding with Python and dtumathtools"
    echo ""
    echo "Need help? Visit: https://pythonsupport.dtu.dk"
    echo "Questions? Email: pythonsupport@dtu.dk"
else
    echo ""
    echo "Installation completed but with some issues detected."
    echo "A diagnostic report has been generated for troubleshooting."
    echo ""
    echo "For support:"
    echo "• Visit: https://pythonsupport.dtu.dk/install/macos/automated-error.html"
    echo "• Email: pythonsupport@dtu.dk"
    exit 1
fi
