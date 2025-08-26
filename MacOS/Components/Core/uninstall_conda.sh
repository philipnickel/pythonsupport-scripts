#!/bin/bash
# Simple conda uninstaller for DTU Python Support

echo "Removing conda installations..."

# Remove conda directories
rm -rf "$HOME/miniforge3" "$HOME/miniconda3" "$HOME/anaconda3" "$HOME/.conda" 2>/dev/null

# Clean shell configs - only remove conda initialization blocks
for file in ~/.bashrc ~/.zshrc ~/.bash_profile; do
    if [ -f "$file" ]; then
        sed -i.bak '/# >>> conda initialize >>>/,/# <<< conda initialize <<</d' "$file" 2>/dev/null
    fi
done

echo "✓ Conda uninstall completed!"
