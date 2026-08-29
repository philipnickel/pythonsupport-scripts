#!/bin/bash
# @doc
# @name: DTU Miniforge Install (macOS)
# @description: Download and install Miniforge (conda) on macOS
# @category: Core
# @usage: bash Core/Conda/install/install_macOS.sh
# @requirements: macOS, curl
# @notes: Downloads the latest DTU Miniforge installer and runs it in batch mode
# @/doc

set -euo pipefail

PS_FORGE_URL="${PS_FORGE_URL:-https://github.com/dtudk/pythonsupport-forge/releases/latest/download}" #TODO: change to internal site 
arch="$(uname -m)"
installer_name="Miniforge3-MacOSX-${arch}.sh"
install_dir="$HOME/miniforge3-dtu"
tmpdir_path=""

cleanup() {
    if [[ -n "$tmpdir_path" && -d "$tmpdir_path" ]]; then
        rm -rf "$tmpdir_path"
    fi
}
trap cleanup EXIT

echo "=== Installing Miniforge ==="
echo ""

# Check if already installed
if [ -d "$install_dir" ] && [ -x "$install_dir/bin/conda" ]; then
    echo "  Miniforge is already installed at $install_dir"
    echo "  [OK] Skipping download"
else
    if [[ "${PS_OFFLINE:-0}" == "1" ]]; then
        case "$arch" in
            arm64) bundle_platform="macos-arm64" ;;
            x86_64) bundle_platform="macos-x86_64" ;;
            *) echo "Unsupported macOS architecture: $arch" >&2; exit 1 ;;
        esac
        installer_path="${PS_BUNDLE_ROOT:?PS_BUNDLE_ROOT is required in offline mode}/bundle_assets/miniforge/$bundle_platform/Miniforge3.sh"
        [[ -f "$installer_path" ]] || {
            echo "Missing offline Miniforge installer: $installer_path" >&2
            exit 1
        }
        echo "  Using bundled ${installer_name}"
    else
        tmpdir_path="$(mktemp -d)"
        installer_path="$tmpdir_path/${installer_name}"
        echo "  Downloading ${installer_name}..."
        curl -fSL "${PS_FORGE_URL}/${installer_name}" -o "$installer_path"
        echo "  [OK] Download complete"
    fi

    # Run installer in batch mode (no prompts, no PATH modification)
    echo "  Running installer..."
    # Installer options:
    # '-b': run non interactively
    # '-u': update an existing installation if there is one
    # '-c': don't modify shell rc files
    bash "$installer_path" -buc -p "$install_dir"
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
