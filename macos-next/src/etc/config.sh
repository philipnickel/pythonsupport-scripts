#!/usr/bin/env bash
# Central config: versions, URLs, checksums, packages
set -euo pipefail
IFS=$' \t\n'

# Python/Conda
MINIFORGE_PATH="${MINIFORGE_PATH:-$HOME/miniforge3}"
# Pin a specific Miniforge release (example version; update with real checksums)
MINIFORGE_VERSION="24.3.0-0"
MINIFORGE_URL_ARM64="https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Miniforge3-MacOSX-arm64.sh"
MINIFORGE_URL_X86_64="https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Miniforge3-MacOSX-x86_64.sh"
# Placeholders — update with actual values when enabling installs
MINIFORGE_SHA256_ARM64="TBD"
MINIFORGE_SHA256_X86_64="TBD"

# Python version and DTU packages
PYTHON_VERSION_DTU="3.12"
# Package sets
# Prefer conda for heavy scientific packages; use pip for DTU-specific ones
CONDA_PACKAGES=(pandas scipy statsmodels uncertainties)
PIP_PACKAGES=(dtumathtools)

# VS Code (optional; pins when enabled)
VSCODE_URL_UNIVERSAL="https://update.code.visualstudio.com/latest/darwin/universal/stable"
VSCODE_SHA256_UNIVERSAL="TBD"
