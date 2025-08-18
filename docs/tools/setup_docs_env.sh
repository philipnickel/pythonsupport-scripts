#!/bin/bash

echo "Setting up documentation environment in pythonsupport conda env..."

# Source conda
if [ -f ~/miniconda3/etc/profile.d/conda.sh ]; then
    source ~/miniconda3/etc/profile.d/conda.sh
elif [ -f ~/anaconda3/etc/profile.d/conda.sh ]; then
    source ~/anaconda3/etc/profile.d/conda.sh
elif command -v conda >/dev/null 2>&1; then
    eval "$(conda shell.bash hook)"
fi

# Activate pythonsupport environment
conda activate pythonsupport

# Install required packages
echo "Installing markdown and watchdog packages..."
pip install markdown>=3.5.0 watchdog>=3.0.0

echo "✅ Documentation environment setup complete!"
echo "Now you can run:"
echo "  conda activate pythonsupport"
echo "  python3 tools/serve_docs.py --regenerate --watch"