#!/bin/bash
# VS Code uninstaller for DTU Python Support
# Performs clean uninstall of VS Code and all user data

echo "Starting VS Code uninstall process..."

# Function to safely remove VS Code application
remove_vscode_application() {
    local app_path="/Applications/Visual Studio Code.app"
    
    if [ -d "$app_path" ]; then
        echo "Found VS Code application at: $app_path"
        
        # Check if we need administrator privileges
        local needs_sudo=false
        if [[ ! -w "/Applications" ]]; then
            needs_sudo=true
        fi
        
        # Check if we're already running with administrator privileges
        if [[ "$EUID" -eq 0 ]]; then
            needs_sudo=false
        fi
        
        echo "Removing VS Code application..."
        if [ "$needs_sudo" = true ]; then
            if [[ "${CLI_MODE:-}" == "true" ]]; then
                # CLI mode - use sudo directly
                echo "Please enter the password to your computer to continue (you will not be able to see what you type)"
                sudo rm -rf "$app_path"
            else
                # GUI mode - use osascript for native authentication
                if osascript -e "do shell script \"rm -rf '$app_path'\" with prompt \"DTU Python Support needs administrator privileges to remove VS Code.\" with administrator privileges"; then
                    echo "VS Code application removed successfully"
                else
                    echo "User cancelled authentication or removal failed"
                    echo "Uninstall aborted by user."
                    exit 1
                fi
            fi
        else
            rm -rf "$app_path"
        fi
        echo "VS Code application removed"
    else
        echo "VS Code application not found at $app_path"
    fi
}

# Function to remove user data folders
remove_user_data() {
    echo "Removing VS Code user data..."
    
    # Remove user data folder
    if [ -d "$HOME/Library/Application Support/Code" ]; then
        echo "Removing user data: $HOME/Library/Application Support/Code"
        rm -rf "$HOME/Library/Application Support/Code"
    else
        echo "User data folder not found"
    fi
    
    # Remove settings and extensions folder
    if [ -d "$HOME/.vscode" ]; then
        echo "Removing settings and extensions: $HOME/.vscode"
        rm -rf "$HOME/.vscode"
    else
        echo "Settings folder not found"
    fi
}

# Remove VS Code application
remove_vscode_application

# Remove user data
remove_user_data

echo "VS Code uninstall completed!"