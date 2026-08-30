#!/bin/bash
# @doc
# @name: Uninstall Miniforge/Conda
# @description: Uninstall Miniforge3/conda and remove all user data on macOS
# @category: Utilities
# @usage: bash "Install macOS.command" uninstall-conda
# @requirements: macOS
# @notes: Removes conda installation, shell initialization, and config files
# @/doc

set -euo pipefail

if [[ "${PS_ENV_INITIALIZED:-0}" != "1" ]]; then
    echo "Environment is not initialized. Use Install macOS.command." >&2
    exit 2
fi

echo "=== Uninstalling Miniforge3/Conda ==="
echo ""

removed_something=false

# Find conda base prefix
conda_base=""

# Try conda command first
if command -v conda &>/dev/null; then
    conda_base="$(conda info --base 2>/dev/null || true)"
fi

# Fallback: check common install locations
if [ -z "$conda_base" ] || [ ! -d "$conda_base" ]; then
    for candidate in "$HOME/miniforge3" "$HOME/miniconda3" "$HOME/anaconda3"; do
        if [ -d "$candidate" ]; then
            conda_base="$candidate"
            break
        fi
    done
fi

if [ -z "$conda_base" ]; then
    echo "  conda not found"
else
    echo "  Found conda at: $conda_base"

    # Safety check: refuse to delete home or root
    resolved_path="$(cd "$conda_base" && pwd)"
    if [ "$resolved_path" = "/" ] || [ "$resolved_path" = "$HOME" ]; then
        echo "  ERROR: Refusing to delete unsafe path: $resolved_path"
        exit 1
    fi

    # Undo shell initialization
    if command -v conda &>/dev/null; then
        conda init --reverse --all 2>/dev/null && \
            echo "  [OK] Shell initialization reversed" || \
            echo "  WARNING: Could not reverse conda init (may be okay)"
    fi

    # Remove conda installation
    if [ -d "$conda_base" ]; then
        if [ -w "$conda_base" ]; then
            rm -rf "$conda_base"
        else
            sudo rm -rf "$conda_base"
        fi
        echo "  [OK] Conda installation removed"
        removed_something=true
    fi
fi

# Remove user configuration
if [ -f "$HOME/.condarc" ]; then
    rm -f "$HOME/.condarc"
    echo "  [OK] Removed .condarc"
    removed_something=true
fi

if [ -d "$HOME/.conda" ]; then
    rm -rf "$HOME/.conda"
    echo "  [OK] Removed .conda"
    removed_something=true
fi

echo ""
if [ "$removed_something" = true ]; then
    echo "=== Uninstall complete! Restart your terminal. ==="
else
    echo "No changes made - conda not found."
fi
