#!/bin/bash
# @doc
# @name: Visual Studio Code Diagnostics
# @description: Checks Visual Studio Code installation and extensions
# @category: Diagnostics
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Diagnostics/Components/vscode_check.sh)"
# @requirements: macOS system
# @notes: Checks VSCode installation and essential extensions
# @/doc

_prefix="PYS:"

echo "VISUAL STUDIO CODE"
echo "------------------"
if command -v code > /dev/null; then
    echo "✓ Visual Studio Code is installed"
    echo "  Version: $(code --version | head -n 1)"
    echo "  Location: $(which code)"
    
    # Check for key extensions
    echo "  Key extensions:"
    missing_extensions=0
    for ext in ms-python.python ms-toolsai.jupyter tomoki1207.pdf; do
        if code --list-extensions | grep -q "^$ext$"; then
            echo "    ✓ $ext"
        else
            echo "    ✗ $ext"
            missing_extensions=$((missing_extensions + 1))
        fi
    done
    
    echo "  All installed extensions (subset):"
    code --list-extensions 2>&1 | head -n 50 | sed 's/^/    /'
    
    echo ""
    if [ $missing_extensions -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
else
    echo "✗ Visual Studio Code is not installed"
    
    # Check for VS Code in common locations
    if [ -d "/Applications/Visual Studio Code.app" ]; then
        echo "  Found in Applications but not in PATH"
        echo "  Consider adding to PATH or reinstalling"
        echo ""
        exit 1
    else
        echo "  Recommended for Python development"
        echo ""
        exit 2
    fi
fi
