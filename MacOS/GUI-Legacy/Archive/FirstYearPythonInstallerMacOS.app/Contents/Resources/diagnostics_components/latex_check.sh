#!/bin/bash
# @doc
# @name: LaTeX Diagnostics
# @description: Checks LaTeX installation and related tools
# @category: Diagnostics
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Diagnostics/Components/latex_check.sh)"
# @requirements: macOS system
# @notes: Checks TeX Live, Pandoc, and nbconvert for PDF export
# @/doc

_prefix="PYS:"

echo "LATEX"
echo "-----"
if command -v tlmgr > /dev/null; then
    echo "✓ TeX Live is installed"
    echo "  Location: $(which tlmgr)"
    echo "  tlmgr version: $(tlmgr --version | head -n 1)"
    
    # Check for pandoc
    if command -v pandoc > /dev/null; then
        echo "✓ Pandoc is installed"
        echo "  Version: $(pandoc --version | head -n 1)"
    else
        echo "✗ Pandoc is not installed"
    fi
    
    # Check for nbconvert
    if python3 -c "import nbconvert" 2>/dev/null; then
        echo "✓ nbconvert is available"
    else
        echo "✗ nbconvert is not available"
    fi
    
    echo "  TeX utilities availability:"
    for bin in pdflatex xelatex lualatex; do
        if command -v "$bin" >/dev/null; then
            echo "    ✓ $bin: $($bin --version | head -n 1)"
        else
            echo "    ✗ $bin: not found"
        fi
    done
    
    echo ""
    exit 0
else
    echo "✗ TeX Live is not installed"
    echo "  Required for PDF export from Jupyter notebooks"
    echo ""
    exit 2
fi
