#!/bin/bash
# @doc
# @name: Python Uninstall (macOS)
# @description: Uninstall python.org Python installations on macOS
# @category: Utilities
# @usage: bash Utils/Python/uninstall_macOS.sh
# @requirements: macOS
# @notes: Removes Python framework installations from python.org (3.x).
#         Does NOT touch the system Python or conda/Homebrew-managed Python.
# @/doc

set -euo pipefail

framework_dir="/Library/Frameworks/Python.framework"
applications_dir="/Applications"

echo "=== Uninstalling python.org Python installations ==="
echo ""

removed_something=false

# Find installed Python versions in the framework directory
if [ -d "$framework_dir/Versions" ]; then
    for version_dir in "$framework_dir/Versions"/3.*; do
        [ -d "$version_dir" ] || continue
        version="$(basename "$version_dir")"
        echo "  Found Python $version"
    done
else
    echo "  No python.org Python installations found."
    echo ""
    echo "No changes made."
    exit 0
fi

# Remove Python framework
echo ""
echo "  Removing $framework_dir ..."
if [ -w "$framework_dir" ]; then
    rm -rf "$framework_dir"
else
    sudo rm -rf "$framework_dir"
fi
echo "  [OK] Python framework removed"
removed_something=true

# Remove Python application folders (e.g. /Applications/Python 3.12)
for app_dir in "$applications_dir"/Python\ 3.*; do
    [ -d "$app_dir" ] || continue
    echo "  Removing $app_dir ..."
    if [ -w "$app_dir" ]; then
        rm -rf "$app_dir"
    else
        sudo rm -rf "$app_dir"
    fi
    echo "  [OK] Removed $(basename "$app_dir")"
    removed_something=true
done

# Remove symlinks in /usr/local/bin that point to the Python framework
if [ -d /usr/local/bin ]; then
    for link in /usr/local/bin/python3* /usr/local/bin/pip3* /usr/local/bin/idle3* /usr/local/bin/pydoc3* /usr/local/bin/2to3*; do
        [ -L "$link" ] || continue
        target="$(readlink "$link")"
        if [[ "$target" == *"Python.framework"* ]]; then
            echo "  Removing symlink $link -> $target"
            if [ -w /usr/local/bin ]; then
                rm -f "$link"
            else
                sudo rm -f "$link"
            fi
            removed_something=true
        fi
    done
    if [ "$removed_something" = true ]; then
        echo "  [OK] Symlinks cleaned up"
    fi
fi

echo ""
if [ "$removed_something" = true ]; then
    echo "=== Uninstall complete! ==="
else
    echo "No changes made."
fi
