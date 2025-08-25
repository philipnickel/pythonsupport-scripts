#!/bin/bash
# @doc
# @name: Conda Uninstall Script
# @description: Completely removes conda/miniconda/miniforge installations
# @category: Core
# @usage: ./uninstall_conda.sh
# @requirements: macOS system
# @notes: Removes conda installations and cleans up shell configurations
# @/doc

# Load configuration
source <(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/config.sh")

echo "DTU Conda Uninstall Script"
echo "=========================="
echo ""

# Find conda installations
CONDA_PATHS=()
CONDA_TYPES=()

# Check common installation locations
if [ -d "$HOME/miniforge3" ]; then
    CONDA_PATHS+=("$HOME/miniforge3")
    CONDA_TYPES+=("Miniforge")
fi

if [ -d "$HOME/miniconda3" ]; then
    CONDA_PATHS+=("$HOME/miniconda3")
    CONDA_TYPES+=("Miniconda")
fi

if [ -d "$HOME/anaconda3" ]; then
    CONDA_PATHS+=("$HOME/anaconda3")
    CONDA_TYPES+=("Anaconda")
fi

if [ -d "/opt/miniconda3" ]; then
    CONDA_PATHS+=("/opt/miniconda3")
    CONDA_TYPES+=("Miniconda (system)")
fi

if [ -d "/opt/anaconda3" ]; then
    CONDA_PATHS+=("/opt/anaconda3")
    CONDA_TYPES+=("Anaconda (system)")
fi

# Show what was found
if [ ${#CONDA_PATHS[@]} -eq 0 ]; then
    echo "No conda installations found to uninstall."
    exit 0
fi

echo "Found conda installations:"
for i in "${!CONDA_PATHS[@]}"; do
    echo "• ${CONDA_TYPES[$i]}: ${CONDA_PATHS[$i]}"
done
echo ""

# Confirm uninstall (skip prompt in non-interactive mode or CI)
echo "This will completely remove all conda installations and clean up your shell configuration."
echo "WARNING: This action cannot be undone!"

if [[ -t 0 ]] && [[ "${PIS_ENV:-}" != "CI" ]] && [[ "${CI:-}" != "true" ]]; then
    # Interactive mode - ask for confirmation
    echo ""
    read -p "Continue with uninstall? (yes/no): " -r
    if [[ ! "$REPLY" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi
else
    # Non-interactive mode or CI - proceed automatically
    echo "Running in non-interactive mode - proceeding with uninstall..."
fi

echo ""
echo "Uninstalling conda installations..."

# 1. Run conda init --reverse to clean up shell configurations
for path in "${CONDA_PATHS[@]}"; do
    if [ -x "$path/bin/conda" ]; then
        echo "• Cleaning up shell configuration for $path"
        "$path/bin/conda" init --reverse --all 2>/dev/null || true
    fi
done

# 2. Remove installation directories
for i in "${!CONDA_PATHS[@]}"; do
    path="${CONDA_PATHS[$i]}"
    type="${CONDA_TYPES[$i]}"
    
    if [ -d "$path" ]; then
        echo "• Removing $type installation: $path"
        
        # Handle system installations (need sudo)
        if [[ "$path" == /opt/* ]]; then
            sudo rm -rf "$path"
        else
            rm -rf "$path"
        fi
        
        if [ $? -eq 0 ]; then
            echo "  ✓ Successfully removed $path"
        else
            echo "  ✗ Failed to remove $path"
        fi
    fi
done

# 3. Clean up shell configuration files
echo "• Cleaning up shell configuration files..."
SHELL_FILES=(
    "$HOME/.bashrc"
    "$HOME/.bash_profile" 
    "$HOME/.zshrc"
    "$HOME/.profile"
)

for file in "${SHELL_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  Cleaning $file"
        
        # Create backup
        cp "$file" "${file}.backup-$(date +%Y%m%d_%H%M%S)"
        
        # Remove conda-related lines
        sed -i '' '/# >>> conda initialize >>>/,/# <<< conda initialize <<</d' "$file" 2>/dev/null || true
        sed -i '' '/miniforge3/d' "$file" 2>/dev/null || true
        sed -i '' '/miniconda3/d' "$file" 2>/dev/null || true
        sed -i '' '/anaconda3/d' "$file" 2>/dev/null || true
        sed -i '' '/conda/d' "$file" 2>/dev/null || true
    fi
done

# 4. Remove conda-related environment variables and aliases
echo "• Cleaning up environment variables..."

# Remove from current session
unset CONDA_DEFAULT_ENV CONDA_EXE CONDA_PREFIX CONDA_PROMPT_MODIFIER CONDA_PYTHON_EXE CONDA_SHLVL
unset _CE_CONDA _CE_M

# 5. Clean up PATH
echo "• Cleaning up PATH..."
export PATH=$(echo "$PATH" | sed -e 's/:*[^:]*conda[^:]*:*/:/g' -e 's/^://' -e 's/:$//')

# 6. Remove conda configuration directory
if [ -d "$HOME/.conda" ]; then
    echo "• Removing conda configuration directory: $HOME/.conda"
    rm -rf "$HOME/.conda"
fi

# 7. Remove conda environments directory (if separate)
if [ -d "$HOME/.conda-env" ]; then
    echo "• Removing conda environments directory: $HOME/.conda-env"
    rm -rf "$HOME/.conda-env"
fi

echo ""
echo "✓ Conda uninstall completed!"
echo ""
echo "Important notes:"
echo "• Shell configuration files have been cleaned up"  
echo "• Backups of shell files were created with .backup-* suffix"
echo "• You may need to restart your terminal or run 'source ~/.bashrc' (or ~/.zshrc)"
echo "• The PATH has been cleaned up for this session"
echo ""
echo "You can now run the DTU installer to install Miniforge."