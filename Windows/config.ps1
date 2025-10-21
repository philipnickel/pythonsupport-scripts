# DTU Python Support Configuration
# This file contains all the configuration variables used across the installation scripts

# Python version configuration
$script:PYTHON_VERSION_DTU = "3.11"

# Required DTU packages
$script:DTU_PACKAGES = @(
    "dtumathtools"
    "pandas"
    "scipy" 
    "statsmodels"
    "uncertainties"
)

# VS Code extensions to install
$script:VSCODE_EXTENSIONS = @(
    "ms-python.python"
    "ms-python.pylint"
    "ms-toolsai.jupyter"
    #"tomoki1207.pdf"
)

# Installation paths
$script:MINIFORGE_PATH = "$env:USERPROFILE\miniforge3"

# URLs and repositories (architecture will be detected at runtime)
$script:MINIFORGE_BASE_URL = "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Windows"

# Logging configuration  
$script:LOG_PREFIX = "DTU_INSTALL"
$script:LOG_DIR = $env:TEMP

# Export variables for use in other scripts
$env:PYTHON_VERSION_DTU = $PYTHON_VERSION_DTU
$env:MINIFORGE_PATH = $MINIFORGE_PATH
$env:LOG_PREFIX = $LOG_PREFIX
$env:LOG_DIR = $LOG_DIR
