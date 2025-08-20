#!/bin/bash
# @name: LaTeX Installation Check
# @description: Check LaTeX/TeX Live installation and related tools
# @category: Development
# @subcategory: LaTeX
# @timeout: 10

echo "LATEX INSTALLATION CHECK"
echo "========================"

latex_found=0

# Check for TeX Live
echo "TeX Live:"
echo "---------"
if command -v tlmgr >/dev/null 2>&1; then
    tlmgr_path=$(which tlmgr)
    echo "✓ TeX Live is installed"
    echo "  Location: $tlmgr_path"
    latex_found=1
else
    echo "✗ TeX Live is not installed"
fi

echo ""

# Check for specific LaTeX engines
echo "LaTeX Engines:"
echo "-------------"
engines=("pdflatex" "xelatex" "lualatex")

for engine in "${engines[@]}"; do
    if command -v "$engine" >/dev/null 2>&1; then
        version_info=$($engine --version 2>/dev/null | head -1)
        echo "✓ $engine: $version_info"
        latex_found=1
    else
        echo "✗ $engine: Not found"
    fi
done

echo ""

# Check for Pandoc (often used with LaTeX)
echo "Related Tools:"
echo "-------------"
if command -v pandoc >/dev/null 2>&1; then
    pandoc_version=$(pandoc --version 2>/dev/null | head -1)
    echo "✓ Pandoc is installed"
    echo "  Version: $pandoc_version"
else
    echo "✗ Pandoc is not installed"
fi

# Check for nbconvert (for Jupyter to PDF)
if python3 -c "import nbconvert" >/dev/null 2>&1; then
    echo "✓ nbconvert is available"
else
    echo "✗ nbconvert is not available"
fi

echo ""

if [ $latex_found -eq 1 ]; then
    echo "✅ LaTeX installation check complete - PASSED"
else
    echo "Installation options:"
    echo "• MacTeX (full): https://www.tug.org/mactex/"
    echo "• BasicTeX (minimal): brew install --cask basictex"
    echo ""
    echo "⚠ LaTeX not found - INSTALLATION RECOMMENDED"
    exit 1
fi