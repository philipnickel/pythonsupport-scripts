#!/bin/bash
# DTU Python Support - Complete Uninstaller
# Usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/uninstall.sh)"

echo "DTU Python Support - Complete Uninstaller"
echo "=========================================="
echo ""

echo "This will remove:"
echo "• All conda/Python installations (miniforge, miniconda, anaconda)"
echo "• Python packages and environments"
echo "• Shell configuration changes"
echo "• VS Code and extensions (optional)"
echo ""

# Ask about VS Code
read -p "Also remove VS Code and extensions? (y/n): " -r vscode_response

echo ""
echo "Starting uninstall process..."
echo ""

# Remove conda installations
echo "🐍 Removing Python/conda installations..."
rm -rf "$HOME/miniforge3" "$HOME/miniconda3" "$HOME/anaconda3" "$HOME/.conda" 2>/dev/null

# Clean shell configs - only remove conda initialization blocks
echo "🧹 Cleaning shell configurations..."
for file in ~/.bashrc ~/.zshrc ~/.bash_profile; do
    if [ -f "$file" ]; then
        sed -i.bak '/# >>> conda initialize >>>/,/# <<< conda initialize <<</d' "$file" 2>/dev/null
    fi
done

# Remove VS Code if requested
if [[ "$vscode_response" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    echo "💻 Removing VS Code..."
    rm -rf "/Applications/Visual Studio Code.app" 2>/dev/null
    sudo rm -f /usr/local/bin/code 2>/dev/null
    rm -rf "$HOME/.vscode" 2>/dev/null
fi

echo ""
echo "✅ Uninstall completed!"
echo ""
echo "Notes:"
echo "• Restart your terminal to see changes"
echo "• Shell config backups were created with .bak extension"
echo ""