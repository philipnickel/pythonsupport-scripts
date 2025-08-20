#!/bin/bash
# @name: Python Installation Check
# @description: Check Python installations and versions
# @category: Python
# @subcategory: Installation
# @timeout: 10

echo "PYTHON INSTALLATION CHECK"
echo "=========================="

installation_found=0

# Check python3
if command -v python3 >/dev/null 2>&1; then
    python3_path=$(which python3)
    python3_version=$(python3 --version 2>&1)
    echo "✓ python3: $python3_path ($python3_version)"
    installation_found=1
else
    echo "✗ python3: Not found"
fi

# Check python
if command -v python >/dev/null 2>&1; then
    python_path=$(which python)
    python_version=$(python --version 2>&1)
    echo "✓ python: $python_path ($python_version)"
    installation_found=1
else
    echo "✗ python: Not found"
fi

echo ""

# Check package managers
echo "Package Managers:"
echo "----------------"
if command -v pip3 >/dev/null 2>&1; then
    pip3_path=$(which pip3)
    pip3_version=$(pip3 --version 2>&1 | awk '{print $2}')
    echo "✓ pip3: $pip3_path (v$pip3_version)"
else
    echo "✗ pip3: Not found"
fi

if command -v pip >/dev/null 2>&1; then
    pip_path=$(which pip)
    pip_version=$(pip --version 2>&1 | awk '{print $2}')
    echo "✓ pip: $pip_path (v$pip_version)"
else
    echo "✗ pip: Not found"
fi

echo ""

if [ $installation_found -eq 0 ]; then
    echo "❌ No Python installation found"
    exit 1
else
    echo "✅ Python installation check complete - PASSED"
fi