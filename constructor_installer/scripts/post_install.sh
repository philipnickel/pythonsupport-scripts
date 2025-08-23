#!/bin/bash

# Post-install script for DTU Python Environment
# This script runs after the conda environment is installed

set -e

echo "DTU Python Environment: Installing VS Code..."

# Get the installation prefix
PREFIX="${PREFIX:-/Applications/DTU_Python_Environment}"

# Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for this session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        export PATH="/opt/homebrew/bin:$PATH"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        export PATH="/usr/local/bin:$PATH"
    fi
fi

# Install VS Code if not present
if ! command -v code >/dev/null 2>&1; then
    echo "Installing VS Code..."
    brew install --cask visual-studio-code
else
    echo "VS Code already installed"
fi

# Install Python extensions for VS Code
echo "Installing VS Code Python extensions..."
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-toolsai.jupyter

# Create a launcher script
LAUNCHER_SCRIPT="$PREFIX/bin/dtu-python"
cat > "$LAUNCHER_SCRIPT" << 'EOF'
#!/bin/bash
# DTU Python Environment Launcher

# Activate the conda environment
source "$PREFIX/etc/profile.d/conda.sh"
conda activate base

# Launch VS Code with the current directory
code .

echo "DTU Python Environment activated!"
echo "Python version: $(python --version)"
echo "Available packages: dtumathtools, pandas, scipy, statsmodels, uncertainties"
EOF

chmod +x "$LAUNCHER_SCRIPT"

echo "DTU Python Environment installation complete!"
echo "You can now use 'dtu-python' to launch the environment with VS Code"
