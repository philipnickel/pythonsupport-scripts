#!/bin/bash
# DTU Python Support Configuration
# This file contains all the configuration variables used across the installation scripts

# Python version configuration
export PYTHON_VERSION_DTU="3.11"

# Required DTU packages
export DTU_PACKAGES=(
    "dtumathtools"
    "pandas" 
    "scipy"
    "statsmodels"
    "uncertainties"
)

# VS Code extensions to install
export VSCODE_EXTENSIONS=(
    "ms-python.python"
    "ms-python.pylint"
    "ms-toolsai.jupyter"
    "tomoki1207.pdf"
)

# Installation paths
export MINIFORGE_PATH="$HOME/miniforge3"

# URLs and repositories (architecture will be detected at runtime)
export MINIFORGE_BASE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX"

# Logging configuration  
export LOG_PREFIX="DTU_INSTALL"
export LOG_DIR="/tmp"