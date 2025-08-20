#!/bin/bash
# @doc
# @name: Python/Conda Diagnostics
# @description: Checks Python and Conda installations
# @category: Diagnostics
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Diagnostics/Components/python_conda_check.sh)"
# @requirements: macOS system
# @notes: Checks for Conda, Python versions, and essential packages
# @/doc

_prefix="PYS:"

echo "PYTHON/CONDA"
echo "-------------"
if command -v conda > /dev/null; then
    echo "✓ Conda is installed"
    echo "  Version: $(conda --version)"
    echo "  Location: $(which conda)"
    echo "  Base environment: $(conda info --base)"
    echo "  Conda info:"
    echo "  ------------------------------------------"
    conda info 2>&1 | sed 's/^/    /'
    echo "  ------------------------------------------"
    
    # Check active environment
    if [ -n "$CONDA_DEFAULT_ENV" ]; then
        echo "  Active environment: $CONDA_DEFAULT_ENV"
    else
        echo "  Active environment: None"
    fi
    
    # Check Python version in conda
    python_version=$(conda list python | grep "^python " | awk '{print $2}' || echo "Not found")
    echo "  Python version: $python_version"
    
    # Check for key packages
    echo "  Key packages:"
    missing_packages=0
    for pkg in dtumathtools pandas scipy statsmodels uncertainties; do
        if conda list | grep -q "^$pkg "; then
            version=$(conda list | grep "^$pkg " | awk '{print $2}')
            echo "    ✓ $pkg ($version)"
        else
            echo "    ✗ $pkg"
            missing_packages=$((missing_packages + 1))
        fi
    done
    
    echo "  Installed environments:"
    conda env list 2>&1 | sed 's/^/    /'
    
    echo ""
    if [ $missing_packages -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
else
    echo "✗ Conda is not installed"
    
    # Check for system Python
    if command -v python3 > /dev/null; then
        echo "  System Python3: $(python3 --version)"
        echo "  Location: $(which python3)"
        echo "  Note: Conda recommended for DTU courses"
        echo ""
        exit 1
    else
        echo "  No Python installation found"
        echo "  Required for Python development"
        echo ""
        exit 2
    fi
fi
