#!/bin/bash
# @name: Python Environment Configuration
# @description: Check Python environment variables and path configuration
# @category: Python
# @subcategory: Environment
# @timeout: 8

echo "PYTHON ENVIRONMENT CONFIGURATION"
echo "================================"

# Check Python environment variables
echo "Python Environment Variables:"
echo "-----------------------------"
if [ -n "${PYTHONPATH:-}" ]; then
    echo "PYTHONPATH: $PYTHONPATH"
else
    echo "PYTHONPATH: Not set"
fi

if [ -n "${PYTHONHOME:-}" ]; then
    echo "PYTHONHOME: $PYTHONHOME"
else
    echo "PYTHONHOME: Not set"
fi

if [ -n "${VIRTUAL_ENV:-}" ]; then
    echo "VIRTUAL_ENV: $VIRTUAL_ENV (Active virtual environment)"
else
    echo "VIRTUAL_ENV: Not set"
fi

echo ""

# Check Python path configuration
echo "Python Path Configuration:"
echo "--------------------------"
if command -v python3 >/dev/null 2>&1; then
    echo "Python sys.path entries:"
    python3 -c "import sys; [print(f'  {path}') for path in sys.path if path]" 2>/dev/null || echo "  Unable to get Python path"
else
    echo "python3 not available for path check"
fi

echo ""

# Check for common Python issues
echo "Configuration Check:"
echo "-------------------"
issues_found=0

# Check if Python can import basic modules
if command -v python3 >/dev/null 2>&1; then
    if python3 -c "import sys, os" >/dev/null 2>&1; then
        echo "✓ Python can import basic modules"
    else
        echo "✗ Python cannot import basic modules"
        issues_found=1
    fi
else
    echo "✗ python3 not available"
    issues_found=1
fi

echo ""

if [ $issues_found -eq 0 ]; then
    echo "✅ Python environment configuration check complete - PASSED"
else
    echo "⚠ Python environment issues detected - CHECK NEEDED"
    exit 1
fi