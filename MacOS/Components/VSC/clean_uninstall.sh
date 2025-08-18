#!/bin/bash
# @doc
# @name: VS Code Clean Uninstaller
# @description: Completely removes Visual Studio Code and all user data according to official documentation
# @category: VSCode
# @requires: macOS, Administrator privileges
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/VSC/clean_uninstall.sh)"
# @example: ./clean_uninstall.sh
# @notes: Uses master utility system for consistent error handling and logging. Removes VS Code application, user settings folder (~/.vscode), and application support data (~/Library/Application Support/Code). Also handles Homebrew-installed VS Code. This follows the official VS Code uninstall documentation exactly.
# @author: Python Support Team
# @version: 2024-08-18
# @/doc

# Load master utilities
source <(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-macos-components}/MacOS/Components/Shared/master_utils.sh")

log_info "Starting Visual Studio Code clean uninstall..."

# Function to safely remove files/directories if they exist
safe_remove() {
    local path="$1"
    if [ -e "$path" ]; then
        log_info "Removing: $path"
        rm -rf "$path"
        if [ $? -eq 0 ]; then
            log_success "Successfully removed: $path"
        else
            log_warning "Failed to remove: $path"
        fi
    else
        log_info "Path does not exist (skipping): $path"
    fi
}

# Step 1: Remove the Visual Studio Code application
log_info "Removing Visual Studio Code application..."
safe_remove "/Applications/Visual Studio Code.app"

# Step 2: Remove user data folders as per official VS Code documentation
# macOS - Delete $HOME/Library/Application Support/Code and ~/.vscode
log_info "Removing VS Code user data folders..."
safe_remove "$HOME/Library/Application Support/Code"
safe_remove "$HOME/.vscode"

# Step 3: Check if VS Code was installed via Homebrew and remove it
log_info "Checking for Homebrew VS Code installation..."
if command -v brew >/dev/null 2>&1; then
    if brew list --cask | grep -q "visual-studio-code"; then
        log_info "Found Homebrew VS Code installation, removing..."
        brew uninstall --cask visual-studio-code 2>/dev/null || log_warning "Homebrew uninstall completed (may have shown warnings)"
    else
        log_info "No Homebrew VS Code installation found"
    fi
else
    log_info "Homebrew not found, skipping Homebrew cleanup"
fi

# Step 4: Verify removal
log_info "Verifying VS Code removal..."

# Check if the application still exists
if [ -e "/Applications/Visual Studio Code.app" ]; then
    log_error "Visual Studio Code.app still exists in /Applications"
    exit 1
fi

# Check for remaining user data folders
remaining_data=false
for path in "$HOME/.vscode" "$HOME/Library/Application Support/Code"; do
    if [ -e "$path" ]; then
        log_warning "Remaining data found at: $path"
        remaining_data=true
    fi
done

if [ "$remaining_data" = true ]; then
    log_warning "Some VS Code data may still remain"
    exit 1
fi

log_success "Visual Studio Code clean uninstall completed successfully!"
log_info "All VS Code files and settings have been removed"