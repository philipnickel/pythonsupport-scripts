#!/bin/bash
# @doc
# @name: Environment Configuration Diagnostics
# @description: Checks shell configuration and environment setup
# @category: Diagnostics
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Diagnostics/Components/environment_check.sh)"
# @requirements: macOS system
# @notes: Checks shell configuration files and PATH setup
# @/doc

_prefix="PYS:"

echo "SHELL CONFIGURATION"
echo "-------------------"
echo "Current shell: $SHELL"

# Check for conda initialization
conda_configured=false
if [ -f ~/.bashrc ] && grep -q "conda initialize" ~/.bashrc; then
    echo "✓ Conda initialized in ~/.bashrc"
    conda_configured=true
fi

if [ -f ~/.zshrc ] && grep -q "conda initialize" ~/.zshrc; then
    echo "✓ Conda initialized in ~/.zshrc"
    conda_configured=true
fi

# Check for homebrew in PATH
homebrew_configured=false
if [ -f ~/.zprofile ] && grep -q "brew shellenv" ~/.zprofile; then
    echo "✓ Homebrew configured in ~/.zprofile"
    homebrew_configured=true
fi

if [ -f ~/.bash_profile ] && grep -q "brew shellenv" ~/.bash_profile; then
    echo "✓ Homebrew configured in ~/.bash_profile"
    homebrew_configured=true
fi

# Check if conda is in PATH
if echo "$PATH" | grep -q "conda"; then
    echo "✓ Conda found in PATH"
else
    echo "⚠ Conda not found in PATH"
fi

echo ""
echo "Snippet of ~/.zshrc (if present):"
if [ -f ~/.zshrc ]; then
    sed -n '1,120p' ~/.zshrc | sed 's/^/    /'
else
    echo "    (no ~/.zshrc)"
fi

echo ""
echo "Snippet of ~/.zprofile (if present):"
if [ -f ~/.zprofile ]; then
    sed -n '1,120p' ~/.zprofile | sed 's/^/    /'
else
    echo "    (no ~/.zprofile)"
fi

echo ""
if [ "$conda_configured" = true ] && [ "$homebrew_configured" = true ]; then
    exit 0
elif [ "$conda_configured" = true ] || [ "$homebrew_configured" = true ]; then
    exit 1
else
    exit 2
fi
