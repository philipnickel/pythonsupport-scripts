#!/bin/bash
# Post-install script for DTU Python Stack

set -euo pipefail

# Basic conda configuration
conda config --set anaconda_anon_usage off
conda config --set auto_activate_base true

# Shell integration
conda init bash 2>/dev/null || true
conda init zsh 2>/dev/null || true

echo "DTU Python Stack installation completed successfully!"