#!/bin/bash
# Post-install script for DTU Python Stack
# This script runs after constructor installs the base environment

set -euo pipefail

# Get the conda installation path
CONDA_PREFIX="${CONDA_PREFIX:-$HOME/miniconda3}"

# Ensure we're using the newly installed conda
export PATH="$CONDA_PREFIX/bin:$PATH"

echo "DTU Python Stack post-install script starting..."

# Activate the base environment
source "$CONDA_PREFIX/etc/profile.d/conda.sh"
conda activate base

# Verify all packages are installed correctly
echo "Verifying package installations..."
python -c "import dtumathtools, pandas, scipy, statsmodels, uncertainties; print(' All packages imported successfully')"

# Set up conda configuration for optimal behavior
echo "Configuring conda settings..."
conda config --set anaconda_anon_usage off
conda config --set auto_activate_base true
conda config --set channel_priority strict

# Ensure shell integration is properly set up
echo "Setting up shell integration..."
conda init bash 2>/dev/null || true
conda init zsh 2>/dev/null || true

echo "DTU Python Stack post-install completed successfully!"
echo "Python $(python --version) with DTU packages is now available."