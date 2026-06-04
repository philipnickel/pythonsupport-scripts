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

#BASE_URL="https://github.com/philipnickel/miniforge-PIS/releases/latest/download"

BASE_URL="https://github.com/dtudk/pythonsupport-forge/releases/latest/download"
#https://github.com/dtudk/pythonsupport-forge

ARCH="$(uname -m)"
INSTALLER_NAME="Miniforge3-MacOSX-${ARCH}.sh"
INSTALL_DIR="$HOME/miniforge3-dtu"

echo "=== Installing Miniforge ==="
echo ""

# Check if already installed
if [ -d "$INSTALL_DIR" ] && [ -x "$INSTALL_DIR/bin/conda" ]; then
    echo "  Miniforge is already installed at $INSTALL_DIR"
    echo "  [OK] Skipping download"
else
    # Download
    TMPDIR_PATH="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR_PATH"' EXIT

    echo "  Downloading ${INSTALLER_NAME}..."
    curl -fSL "${BASE_URL}/${INSTALLER_NAME}" -o "$TMPDIR_PATH/${INSTALLER_NAME}"
    echo "  [OK] Download complete"

    # Run installer in batch mode (no prompts, no PATH modification)
    echo "  Running installer..."
    bash "$TMPDIR_PATH/${INSTALLER_NAME}" -buc -p "$INSTALL_DIR"
    echo "  [OK] Miniforge installed to $INSTALL_DIR"
fi

# Load conda shell functions and activate the base environment
echo "  Initializing conda..."
. "${INSTALL_DIR}/etc/profile.d/conda.sh" && conda activate "${INSTALL_DIR}"

# Initialize conda for all supported shells on this machine
conda init --all
echo "  [OK] conda init complete (restart your terminal to activate)"

echo ""
echo "=== Miniforge installation complete! ==="
