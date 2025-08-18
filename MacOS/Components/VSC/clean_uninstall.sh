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

# Step 2: Remove user VS Code directories and settings
echo "$_prefix Removing VS Code user data and settings..."

# Remove .vscode directories (extensions and settings)
safe_remove "$HOME/.vscode"
safe_remove "$HOME/.vscode-insiders"

# Remove Application Support directory
safe_remove "$HOME/Library/Application Support/Code"
safe_remove "$HOME/Library/Application Support/Code - Insiders"

# Remove Saved Application State
safe_remove "$HOME/Library/Saved Application State/com.microsoft.VSCode.savedState"
safe_remove "$HOME/Library/Saved Application State/com.microsoft.VSCodeInsiders.savedState"

# Remove Preferences
safe_remove "$HOME/Library/Preferences/com.microsoft.VSCode.plist"
safe_remove "$HOME/Library/Preferences/com.microsoft.VSCode.helper.plist"
safe_remove "$HOME/Library/Preferences/com.microsoft.VSCodeInsiders.plist"
safe_remove "$HOME/Library/Preferences/com.microsoft.VSCodeInsiders.helper.plist"

# Remove Caches
safe_remove "$HOME/Library/Caches/com.microsoft.VSCode"
safe_remove "$HOME/Library/Caches/com.microsoft.VSCode.ShipIt"
safe_remove "$HOME/Library/Caches/com.microsoft.VSCodeInsiders"
safe_remove "$HOME/Library/Caches/com.microsoft.VSCodeInsiders.ShipIt"

# Remove Logs
safe_remove "$HOME/Library/Logs/Visual Studio Code"

# Remove any remaining traces in ~/Library
safe_remove "$HOME/Library/Application Support/Visual Studio Code"

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

# Step 4: Clear command cache
hash -r 2>/dev/null || true

# Step 5: Verify removal
echo "$_prefix Verifying VS Code removal..."

# Check if the application still exists
if [ -e "/Applications/Visual Studio Code.app" ]; then
    echo "$_prefix Warning: Visual Studio Code.app still exists in /Applications"
    exit 1
fi

# Check if code command is still available
if command -v code >/dev/null 2>&1; then
    echo "$_prefix Warning: 'code' command still available in PATH"
    echo "$_prefix Location: $(which code)"
    # This might be okay if there are other VS Code installations or symlinks
fi

# Check for remaining user data
remaining_data=false
for path in "$HOME/.vscode" "$HOME/Library/Application Support/Code" "$HOME/Library/Preferences/com.microsoft.VSCode.plist"; do
    if [ -e "$path" ]; then
        echo "$_prefix Warning: Remaining data found at: $path"
        remaining_data=true
    fi
done

if [ "$remaining_data" = true ]; then
    echo "$_prefix Warning: Some VS Code data may still remain"
    echo "$_prefix You may need to manually remove remaining files"
    exit 1
fi

echo "$_prefix Visual Studio Code clean uninstall completed successfully!"
echo "$_prefix All VS Code files and settings have been removed"
echo ""