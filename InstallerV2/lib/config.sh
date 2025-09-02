#!/usr/bin/env bash

# User-facing flags (parsed in core):
# --cli | --gui | --dry-run | --no-analytics | --prefix=PATH

# Defaults align with existing MacOS/config.sh but isolated here for V2.
DTU_PYTHON_VERSION=${DTU_PYTHON_VERSION:-"3.12"}
DTU_PACKAGES=("dtumathtools" "pandas" "scipy" "statsmodels" "uncertainties")
VSCODE_EXTENSIONS=("ms-python.python" "ms-toolsai.jupyter" "tomoki1207.pdf")

MINIFORGE_BASE_URL=${MINIFORGE_BASE_URL:-"https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX"}
INSTALL_PREFIX=${INSTALL_PREFIX:-"$HOME"}

# Analytics
DTU_ANALYTICS_ENABLED=${DTU_ANALYTICS_ENABLED:-"1"}

