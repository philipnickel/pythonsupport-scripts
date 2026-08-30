#!/bin/bash
# @doc
# @name: Install DTU Miniforge
# @description: Download and install Miniforge (conda) on macOS
# @category: Core
# @usage: bash "Install macOS.command" install-conda
# @requirements: macOS, curl
# @notes: Downloads the latest DTU Miniforge installer and runs it in batch mode
# @/doc

set -euo pipefail

if [[ "${PS_ENV_INITIALIZED:-0}" != "1" ]]; then
    echo "Environment is not initialized. Use Install macOS.command or install_all_macOS.sh." >&2
    exit 2
fi

arch="$PS_ARCH"
installer_name="Miniforge3-MacOSX-${arch}.sh"
install_dir="$HOME/miniforge3-dtu"
tmpdir_path=""
installed_now=0
release_payload=""

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
    if [[ "$PS_ENV" == "offline" ]]; then
        installer_path="${PS_BUNDLE_ROOT:?PS_BUNDLE_ROOT is required in offline mode}/bundle_assets/miniforge/$PS_BUNDLE_PLATFORM/Miniforge3.sh"
        [[ -f "$installer_path" ]] || {
            echo "Missing offline Miniforge installer: $installer_path" >&2
            exit 1
        }
        echo "  Using bundled ${installer_name}"
    else
        tmpdir_path="$(mktemp -d)"
        installer_path="$tmpdir_path/${installer_name}"
        echo "  Downloading ${installer_name}..."
        forge_url="${PS_FORGE_URL:?PS_FORGE_URL is required online}"
        curl -fSL "${forge_url%/}/${installer_name}" -o "$installer_path"
        release_payload="$(curl -fsSL --connect-timeout 2 --max-time 5 \
            "https://api.github.com/repos/dtudk/pythonsupport-forge/releases/latest" 2>/dev/null || true)"
        echo "  [OK] Download complete"
    fi

    # Run installer in batch mode (no prompts, no PATH modification)
    echo "  Running installer..."
    # Installer options:
    # '-b': run non interactively
    # '-u': update an existing installation if there is one
    # '-c': don't modify shell rc files
    bash "$installer_path" -buc -p "$install_dir"
    installed_now=1
    echo "  [OK] Miniforge installed to $install_dir"
fi

if (( installed_now )); then
    dtu_release=""
    miniforge_version=""
    if [[ "$PS_ENV" == "offline" ]]; then
        dtu_release="${PS_DTU_RELEASE:-}"
        miniforge_version="${PS_MINIFORGE_VERSION:-}"
    else
        dtu_release="$(sed -nE 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' <<< "$release_payload" | head -n 1)"
        miniforge_version="$(sed -nE 's/.*"name"[[:space:]]*:[[:space:]]*"Miniforge3-([0-9][0-9.]*-[0-9]+)-MacOSX-.*/\1/p' <<< "$release_payload" | head -n 1)"
    fi
    if [[ -n "$dtu_release" ]]; then
        installed_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        printf '{\n  "schema": 1,\n  "dtuRelease": "%s",\n  "miniforgeVersion": "%s",\n  "installedAt": "%s",\n  "source": "%s"\n}\n' \
            "$dtu_release" "$miniforge_version" "$installed_at" "$PS_ENV" > "$install_dir/.dtu-python-support.json"
    else
        echo "  [WARNING] Could not determine the DTU release; installation marker was not written" >&2
    fi
fi

# Load conda shell functions and activate the base environment
echo "  Initializing conda..."
source "${install_dir}/etc/profile.d/conda.sh" && conda activate "${install_dir}"

# Initialize conda for all supported shells on this machine
conda init --all
echo "  [OK] conda init complete (restart your terminal to activate)"

echo ""
echo "=== Miniforge installation complete! ==="
