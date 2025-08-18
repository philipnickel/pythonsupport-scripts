#!/bin/bash
# @doc
# @name: Python Uninstaller
# @description: Removes Python installations and related files from macOS system
# @category: Python
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/uninstall_python.sh)"
# @requirements: macOS system with admin privileges
# @notes: Removes Python from multiple locations including Library, Applications, and system paths. Requires sudo access.
# @/doc



_prefix="PYS:"

echo "$_prefix Uninstalling Python installations"

echo "$_prefix Deleting Python in $HOME/Library/Python"
sudo rm -rf ~/Library/Python

echo "$_prefix Deleting Python in /Application/Python"
sudo rm -rf /Applications/Python*

echo "$_prefix Deleting Python in /Library/Frameworks/Python.framework"
sudo rm -rf /Library/Frameworks/Python.framework

# Note: We don't remove system Python executables as they may be required by macOS

echo "$_prefix Python uninstall completed"