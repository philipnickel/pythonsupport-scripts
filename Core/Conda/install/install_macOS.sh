#!/bin/bash
# @doc
# @name: Miniforge Install (macOS)
# @description: Download and install Miniforge (conda) on macOS
# @category: Core
# @usage: bash Core/Conda/install/install_macOS.sh
# @requirements: macOS, curl
# @notes: Downloads the latest Miniforge installer and runs it in batch mode
# @/doc

set -euo pipefail

PS_FORGE_URL="${PS_FORGE_URL:-https://github.com/philipnickel/miniforge-PIS/releases/latest/download}"
arch="$(uname -m)"
installer_name="Miniforge3-MacOSX-${arch}.sh"
install_dir="$HOME/miniforge3-dtu"

echo "=== Installing Miniforge ==="
echo ""

# Check if already installed
if [ -d "$install_dir" ] && [ -x "$install_dir/bin/conda" ]; then
    echo "  Miniforge is already installed at $install_dir"
    echo "  [OK] Skipping download"
else
    # Download
    tmpdir_path="$(mktemp -d)"
    trap "rm -rf '$tmpdir_path'" EXIT

    echo "  Downloading ${installer_name}..."
    curl -fSL "${PS_FORGE_URL}/${installer_name}" -o "$tmpdir_path/${installer_name}"
    echo "  [OK] Download complete"

    # Run installer in batch mode (no prompts, no PATH modification)
    echo "  Running installer..."
    # Installer options:
    # '-b': run non interactively
    # '-u': update an existing installation if there is one
    # '-c': don't modify shell rc files
    bash "$tmpdir_path/${installer_name}" -buc -p "$install_dir"
    echo "  [OK] Miniforge installed to $install_dir"
fi

# Load conda shell functions and activate the base environment
echo "  Initializing conda..."
source "${install_dir}/etc/profile.d/conda.sh" && conda activate "${install_dir}"

# Initialize conda for all supported shells on this machine
conda init --all
echo "  [OK] conda init complete (restart your terminal to activate)"

echo ""
echo "=== Miniforge installation complete! ==="
