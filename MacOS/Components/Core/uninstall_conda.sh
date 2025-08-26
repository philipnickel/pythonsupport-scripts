#!/bin/bash
# Simple conda uninstaller for DTU Python Support

echo "Starting conda uninstall process..."

# Check what conda installations exist
echo "Checking for existing conda installations..."

if [ -d "$HOME/miniforge3" ]; then
    echo "Found miniforge3 installation at: $HOME/miniforge3"
    echo "Removing miniforge3..."
    rm -rf "$HOME/miniforge3"
    echo "Miniforge3 removed"
fi

if [ -d "$HOME/miniconda3" ]; then
    echo "Found miniconda3 installation at: $HOME/miniconda3"
    echo "Removing miniconda3..."
    rm -rf "$HOME/miniconda3"
    echo "Miniconda3 removed"
fi

if [ -d "$HOME/anaconda3" ]; then
    echo "Found anaconda3 installation at: $HOME/anaconda3"
    echo "Removing anaconda3..."
    rm -rf "$HOME/anaconda3"
    echo "Anaconda3 removed"
fi

if [ -d "$HOME/.conda" ]; then
    echo "Found conda configuration at: $HOME/.conda"
    echo "Removing conda configuration..."
    rm -rf "$HOME/.conda"
    echo "Conda configuration removed"
fi

# Clean shell configs - only remove conda initialization blocks
echo "Cleaning shell configuration files..."

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
