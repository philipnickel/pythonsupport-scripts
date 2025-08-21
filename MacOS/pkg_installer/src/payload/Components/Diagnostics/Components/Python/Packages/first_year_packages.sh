#!/bin/bash
# @name: First Year Required Packages
# @description: Check if DTU first year required Python packages are installed
# @category: Python
# @subcategory: Packages
# @timeout: 15

echo "FIRST YEAR REQUIRED PACKAGES"
echo "============================"

# Define required packages for first year DTU students
python_packages=(dtumathtools pandas scipy statsmodels uncertainties numpy matplotlib jupyter)

# Determine which Python command to use
python_cmd="python3"
if ! command -v python3 > /dev/null 2>&1; then
    if command -v python > /dev/null 2>&1; then
        python_cmd="python"
        echo "ℹ Using 'python' command (python3 not found)"
    else
        echo "FAIL No Python installation found"
        exit 1
    fi
fi

echo "Checking packages in: $($python_cmd --version)"
echo ""

missing_packages=0
installed_packages=0

echo "Required Packages:"
echo "-----------------"
for pkg in "${python_packages[@]}"; do
    if $python_cmd -c "import $pkg" > /dev/null 2>&1; then
        # Try to get version
        version=$($python_cmd -c "import $pkg; print(getattr($pkg, '__version__', 'unknown'))" 2>/dev/null || echo "unknown")
        echo "  PASS $pkg ($version)"
        installed_packages=$((installed_packages + 1))
    else
        echo "  FAIL $pkg - MISSING"
        missing_packages=$((missing_packages + 1))
    fi
done

echo ""
echo "Summary:"
echo "--------"
echo "Installed: $installed_packages/${#python_packages[@]}"
echo "Missing: $missing_packages/${#python_packages[@]}"

if [ $missing_packages -eq 0 ]; then
    echo "PASSED All required packages are installed"
    exit 0
else
    echo ""
    echo "Installation suggestions:"
    echo "• Install missing packages with: pip install <package-name>"
    echo "• Or use conda: conda install <package-name>"
    echo ""
    echo "⚠ Some required packages missing - CHECK NEEDED"
    exit 1
fi