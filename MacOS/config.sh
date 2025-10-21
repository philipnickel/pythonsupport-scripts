#!/bin/bash
# DTU Python Support Configuration

# Python version for DTU first year courses
export PYTHON_VERSION_DTU="3.12"

# Required DTU packages
export DTU_PACKAGES=("dtumathtools" "pandas" "scipy" "statsmodels" "uncertainties")

# VS Code extensions
export VSCODE_EXTENSIONS=("ms-python.python" "ms-toolsai.jupyter")

# Miniforge configuration
export MINIFORGE_PATH="$HOME/miniforge3"
export MINIFORGE_BASE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX"

