#!/bin/bash

_prefix="PYS:"

echo "$_prefix Starting Visual Studio Code clean uninstall..."

# Function to safely remove files/directories if they exist
safe_remove() {
    local path="$1"
    if [ -e "$path" ]; then
        echo "$_prefix Removing: $path"
        rm -rf "$path"
        if [ $? -eq 0 ]; then
            echo "$_prefix Successfully removed: $path"
        else
            echo "$_prefix Warning: Failed to remove: $path"
        fi
    else
        echo "$_prefix Path does not exist (skipping): $path"
    fi
}

# Step 1: Remove the Visual Studio Code application
echo "$_prefix Removing Visual Studio Code application..."
safe_remove "/Applications/Visual Studio Code.app"

# Step 2: Remove user data folders as per official VS Code documentation
# macOS - Delete $HOME/Library/Application Support/Code and ~/.vscode
echo "$_prefix Removing VS Code user data folders..."
safe_remove "$HOME/Library/Application Support/Code"
safe_remove "$HOME/.vscode"

# Step 3: Check if VS Code was installed via Homebrew and remove it
echo "$_prefix Checking for Homebrew VS Code installation..."
if command -v brew >/dev/null 2>&1; then
    if brew list --cask | grep -q "visual-studio-code"; then
        echo "$_prefix Found Homebrew VS Code installation, removing..."
        brew uninstall --cask visual-studio-code 2>/dev/null || echo "$_prefix Homebrew uninstall completed (may have shown warnings)"
    else
        echo "$_prefix No Homebrew VS Code installation found"
    fi
else
    echo "$_prefix Homebrew not found, skipping Homebrew cleanup"
fi

# Step 4: Verify removal
echo "$_prefix Verifying VS Code removal..."

# Check if the application still exists
if [ -e "/Applications/Visual Studio Code.app" ]; then
    echo "$_prefix Warning: Visual Studio Code.app still exists in /Applications"
    exit 1
fi

# Check for remaining user data folders
remaining_data=false
for path in "$HOME/.vscode" "$HOME/Library/Application Support/Code"; do
    if [ -e "$path" ]; then
        echo "$_prefix Warning: Remaining data found at: $path"
        remaining_data=true
    fi
done

if [ "$remaining_data" = true ]; then
    echo "$_prefix Warning: Some VS Code data may still remain"
    exit 1
fi

echo "$_prefix Visual Studio Code clean uninstall completed successfully!"
echo "$_prefix All VS Code files and settings have been removed"
echo ""