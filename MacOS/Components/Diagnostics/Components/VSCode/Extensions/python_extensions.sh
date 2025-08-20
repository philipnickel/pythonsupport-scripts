#!/bin/bash
# @name: Python Development Extensions
# @description: Check for essential Python development extensions in VS Code
# @category: VSCode
# @subcategory: Extensions
# @timeout: 10

echo "PYTHON DEVELOPMENT EXTENSIONS"
echo "============================="

# Check if code command is available
if ! command -v code >/dev/null 2>&1; then
    echo "❌ VS Code 'code' command not available"
    echo "Cannot check extensions without VS Code CLI access"
    exit 1
fi

# Required extensions for Python development
required_extensions=(
    "ms-python.python"
    "ms-toolsai.jupyter"
)

# Recommended extensions
recommended_extensions=(
    "ms-python.black-formatter"
    "ms-python.pylint" 
    "ms-python.flake8"
    "tomoki1207.pdf"
)

# Get installed extensions
echo "Checking Python development extensions..."
echo ""

if ! installed_extensions=$(code --list-extensions 2>/dev/null); then
    echo "❌ Unable to retrieve extension list"
    exit 1
fi

missing_required=0
missing_recommended=0

echo "Required Extensions:"
echo "-------------------"
for ext in "${required_extensions[@]}"; do
    if echo "$installed_extensions" | grep -q "^$ext$"; then
        echo "  ✓ $ext"
    else
        echo "  ✗ $ext - MISSING"
        missing_required=$((missing_required + 1))
    fi
done

echo ""
echo "Recommended Extensions:"
echo "----------------------"
for ext in "${recommended_extensions[@]}"; do
    if echo "$installed_extensions" | grep -q "^$ext$"; then
        echo "  ✓ $ext"
    else
        echo "  ✗ $ext - RECOMMENDED"
        missing_recommended=$((missing_recommended + 1))
    fi
done

echo ""
echo "Extension Summary:"
echo "-----------------"
echo "Required extensions missing: $missing_required/${#required_extensions[@]}"
echo "Recommended extensions missing: $missing_recommended/${#recommended_extensions[@]}"

echo ""
if [ $missing_required -eq 0 ]; then
    echo "✅ All required Python extensions are installed"
    if [ $missing_recommended -gt 0 ]; then
        echo "ℹ Consider installing recommended extensions for better development experience"
    fi
else
    echo "Installation commands:"
    echo "• Install Python extension: code --install-extension ms-python.python"
    echo "• Install Jupyter extension: code --install-extension ms-toolsai.jupyter"
    echo ""
    echo "⚠ Some required extensions missing - SETUP NEEDED"
    exit 1
fi