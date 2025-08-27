#!/bin/bash
# Robust conda uninstaller for DTU Python Support
# Follows official Miniforge/Miniconda uninstall procedure

echo "Starting conda uninstall process..."

# Function to safely remove conda installation
remove_conda_installation() {
    local conda_path="$1"
    local conda_type="$2"
    
    if [ -d "$conda_path" ]; then
        echo "Found $conda_type installation at: $conda_path"
        
        # Check if this is a system installation (requires sudo)
        local needs_sudo=false
        if [[ "$conda_path" == /opt/* ]] || [[ "$conda_path" == /usr/local/* ]] || [[ "$conda_path" == /System/* ]]; then
            needs_sudo=true
        fi
        
        # Check if we're already running with administrator privileges
        if [[ "$EUID" -eq 0 ]]; then
            needs_sudo=false
        fi
        
        # In CI mode, only use sudo for system installations
        if [[ "${PIS_ENV:-}" == "CI" ]] && [[ "$needs_sudo" == false ]]; then
            needs_sudo=false
        elif [[ "$EUID" -ne 0 ]]; then
            needs_sudo=true
        fi
        
        # Try to use the official uninstaller script first
        if [ -f "$conda_path/uninstall.sh" ]; then
            echo "Using official $conda_type uninstaller script..."
            if [ "$needs_sudo" = true ]; then
                if [[ "${CLI_MODE:-}" == "true" ]]; then
                    # CLI mode - use sudo directly
                    echo "Please enter the password to your computer to continue (you will not be able to see what you type)"
                    if sudo -E bash "$conda_path/uninstall.sh" --yes; then
                        echo "$conda_type uninstaller completed successfully"
                        return 0
                    else
                        echo "Official uninstaller failed, falling back to manual removal..."
                    fi
                else
                    # GUI mode - use osascript for native authentication
                    if osascript -e "do shell script \"bash '$conda_path/uninstall.sh' --yes\" with prompt \"DTU Python Support needs administrator privileges to run the official conda uninstaller.\" with administrator privileges"; then
                        echo "$conda_type uninstaller completed successfully"
                        return 0
                    else
                        echo "User cancelled authentication or uninstaller failed"
                        echo "Installation aborted by user."
                        exit 1
                    fi
                fi
            else
                if bash "$conda_path/uninstall.sh" --yes; then
                    echo "$conda_type uninstaller completed successfully"
                    return 0
                else
                    echo "Official uninstaller failed, falling back to manual removal..."
                fi
            fi
        fi
        
        # Manual removal if no uninstaller or it failed
        echo "Removing $conda_type manually..."
        if [ "$needs_sudo" = true ]; then
            if [[ "${CLI_MODE:-}" == "true" ]]; then
                # CLI mode - use sudo directly
                echo "Please enter the password to your computer to continue (you will not be able to see what you type)"
                sudo rm -rf "$conda_path"
            else
                # GUI mode - use osascript for native authentication
                if osascript -e "do shell script \"rm -rf '$conda_path'\" with prompt \"DTU Python Support needs administrator privileges to remove the existing conda installation.\" with administrator privileges"; then
                    echo "Conda installation removed successfully"
                else
                    echo "User cancelled authentication or removal failed"
                    echo "Installation aborted by user."
                    exit 1
                fi
            fi
        else
            rm -rf "$conda_path"
        fi
        echo "$conda_type removed"
    fi
}

# Check what conda installations exist
echo "Checking for existing conda installations..."

# Try to get conda info if conda is available
if command -v conda >/dev/null 2>&1; then
    echo "Conda command found, getting installation info..."
    CONDA_BASE=$(conda info --base 2>/dev/null || echo "")
    if [ -n "$CONDA_BASE" ]; then
        echo "Conda base environment: $CONDA_BASE"
        
        # Determine conda type from base path
        if echo "$CONDA_BASE" | grep -q "miniforge"; then
            remove_conda_installation "$CONDA_BASE" "Miniforge"
        elif echo "$CONDA_BASE" | grep -q "miniconda"; then
            remove_conda_installation "$CONDA_BASE" "Miniconda"
        elif echo "$CONDA_BASE" | grep -q "anaconda"; then
            remove_conda_installation "$CONDA_BASE" "Anaconda"
        else
            remove_conda_installation "$CONDA_BASE" "Conda"
        fi
    fi
fi

# Check common installation locations if conda command not available
if [ -d "$HOME/miniforge3" ]; then
    remove_conda_installation "$HOME/miniforge3" "Miniforge"
fi

if [ -d "$HOME/miniconda3" ]; then
    remove_conda_installation "$HOME/miniconda3" "Miniconda"
fi

if [ -d "$HOME/anaconda3" ]; then
    remove_conda_installation "$HOME/anaconda3" "Anaconda"
fi

# Remove conda configuration files
echo "Removing conda configuration files..."

if [ -f "$HOME/.condarc" ]; then
    echo "Removing $HOME/.condarc"
    rm -f "$HOME/.condarc"
fi

if [ -d "$HOME/.conda" ]; then
    echo "Removing $HOME/.conda and underlying files"
    rm -rf "$HOME/.conda"
fi

# Clean shell configs using conda init --reverse if available
echo "Cleaning shell configuration files..."

if command -v conda >/dev/null 2>&1; then
    echo "Using conda init --reverse to clean shell configurations..."
    # In CI mode, don't use sudo for user installations
    if [[ "${PIS_ENV:-}" == "CI" ]] || [[ "$EUID" -eq 0 ]]; then
        conda init --reverse --all 2>/dev/null || echo "conda init --reverse failed, using manual cleanup"
    elif [[ "${CLI_MODE:-}" == "true" ]]; then
        # CLI mode - use sudo directly
        echo "Please enter the password to your computer to continue (you will not be able to see what you type)"
        sudo -E conda init --reverse --all 2>/dev/null || echo "conda init --reverse failed, using manual cleanup"
    else
        # GUI mode - use osascript for native authentication
        if osascript -e "do shell script \"conda init --reverse --all\" with prompt \"DTU Python Support needs administrator privileges to clean up conda shell configurations.\" with administrator privileges" 2>/dev/null; then
            echo "Conda shell configurations cleaned successfully"
        else
            echo "User cancelled authentication or conda init failed, using manual cleanup"
        fi
    fi
fi

# Manual cleanup of shell configs
for file in ~/.bashrc ~/.zshrc ~/.bash_profile; do
    if [ -f "$file" ]; then
        echo "Processing: $file"
        if grep -q "# >>> conda initialize >>>" "$file"; then
            echo "Found conda initialization block in $file, removing..."
            sed -i.bak '/# >>> conda initialize >>>/,/# <<< conda initialize <<</d' "$file"
            echo "Conda initialization block removed from $file"
        else
            echo "No conda initialization block found in $file"
        fi
    else
        echo "File not found: $file"
    fi
done

echo "Conda uninstall completed!"
