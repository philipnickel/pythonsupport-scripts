#!/bin/bash
# Enhanced Python/Conda Diagnostics with Subchecks
# Provides detailed hierarchical checking with individual pass/fail status

set -euo pipefail

# Track subchecks
SUBCHECK_RESULTS=()
TOTAL_SUBCHECKS=0
PASSED_SUBCHECKS=0
FAILED_SUBCHECKS=0

# Function to run subcheck
run_subcheck() {
    local category="$1"
    local name="$2"
    local command="$3"
    local expected_result="$4"  # "pass" or "fail"
    
    TOTAL_SUBCHECKS=$((TOTAL_SUBCHECKS + 1))
    
    echo "  🔍 $category: $name"
    
    local result_text=""
    local status="FAIL"
    
    if eval "$command" > /dev/null 2>&1; then
        if [[ "$expected_result" == "pass" ]]; then
            status="PASS"
            result_text="✓ Passed"
            PASSED_SUBCHECKS=$((PASSED_SUBCHECKS + 1))
        else
            status="FAIL"
            result_text="✗ Unexpected success"
            FAILED_SUBCHECKS=$((FAILED_SUBCHECKS + 1))
        fi
    else
        if [[ "$expected_result" == "fail" ]]; then
            status="PASS"
            result_text="✓ Expected failure"
            PASSED_SUBCHECKS=$((PASSED_SUBCHECKS + 1))
        else
            status="FAIL"
            result_text="✗ Failed"
            FAILED_SUBCHECKS=$((FAILED_SUBCHECKS + 1))
        fi
    fi
    
    # Execute command again to capture output for display
    local output=""
    if eval "$command" > /tmp/subcheck_output_$$ 2>&1; then
        output=$(head -3 /tmp/subcheck_output_$$ 2>/dev/null | tr '\n' ' ')
    else
        output=$(head -3 /tmp/subcheck_output_$$ 2>/dev/null | tr '\n' ' ')
    fi
    rm -f /tmp/subcheck_output_$$
    
    # Store result
    SUBCHECK_RESULTS+=("$category|$name|$status|$output")
    
    echo "    $result_text"
    if [[ -n "$output" && ${#output} -lt 100 ]]; then
        echo "    → $output"
    fi
    echo ""
}

# Function to display detailed output for a category
show_category_details() {
    local category="$1"
    
    echo "  📋 Detailed Results for $category:"
    echo "  ─────────────────────────────────────"
    
    for result in "${SUBCHECK_RESULTS[@]}"; do
        IFS='|' read -r cat name status output <<< "$result"
        if [[ "$cat" == "$category" ]]; then
            if [[ "$status" == "PASS" ]]; then
                echo "    ✅ $name"
            else
                echo "    ❌ $name"
            fi
            
            if [[ -n "$output" ]]; then
                echo "$output" | sed 's/^/      /'
            fi
            echo ""
        fi
    done
}

echo "🐍 PYTHON/CONDA ENVIRONMENT DIAGNOSTICS"
echo "═══════════════════════════════════════"
echo ""

# 1. CONDA INSTALLATION CHECKS
echo "📦 1. CONDA INSTALLATION"
echo "────────────────────────"

run_subcheck "Conda" "Conda Command Available" "command -v conda" "pass"
run_subcheck "Conda" "Conda Executable" "conda --version" "pass"
run_subcheck "Conda" "Conda Info Accessible" "conda info" "pass"

if command -v conda > /dev/null; then
    echo "  📊 Conda Installation Details:"
    echo "    Version: $(conda --version 2>/dev/null | cut -d' ' -f2)"
    echo "    Location: $(which conda)"
    echo "    Base Environment: $(conda info --base 2>/dev/null)"
    echo ""
fi

# 2. PYTHON VERSION CHECKS
echo "🐍 2. PYTHON VERSIONS"
echo "─────────────────────"

run_subcheck "Python" "Python 3 Available" "command -v python3" "pass"
run_subcheck "Python" "Python Version Check" "python3 --version" "pass"

if command -v conda > /dev/null; then
    run_subcheck "Python" "Conda Python Available" "conda run python --version" "pass"
    run_subcheck "Python" "Python in Conda Environment" "conda list python | grep -q '^python '" "pass"
fi

# 3. ENVIRONMENT CHECKS
echo "🌍 3. CONDA ENVIRONMENTS"
echo "────────────────────────"

if command -v conda > /dev/null; then
    run_subcheck "Environment" "Environment List Accessible" "conda env list" "pass"
    
    # Check for common environments
    if conda env list | grep -q "dtuenv"; then
        echo "  ✅ DTU Environment: Found"
    else
        echo "  ℹ️  DTU Environment: Not found (optional)"
    fi
    echo ""
    
    echo "  📋 Available Environments:"
    conda env list 2>/dev/null | grep -E "^\w" | sed 's/^/    /'
    echo ""
fi

# 4. ESSENTIAL PACKAGES
echo "📚 4. ESSENTIAL PACKAGES"
echo "────────────────────────"

if command -v conda > /dev/null; then
    # Core scientific packages
    ESSENTIAL_PACKAGES=(
        "pandas:Data Analysis"
        "numpy:Numerical Computing"  
        "scipy:Scientific Computing"
        "matplotlib:Plotting"
        "jupyter:Interactive Computing"
        "ipython:Enhanced Python Shell"
    )
    
    for pkg_info in "${ESSENTIAL_PACKAGES[@]}"; do
        IFS=':' read -r pkg desc <<< "$pkg_info"
        run_subcheck "Essential" "$desc ($pkg)" "conda list | grep -q '^$pkg '" "pass"
    done
    
    # DTU-specific packages
    echo "  🎓 DTU-Specific Packages:"
    DTU_PACKAGES=(
        "dtumathtools:DTU Math Tools"
        "uncertainties:Uncertainty Calculations"
        "statsmodels:Statistical Models"
    )
    
    for pkg_info in "${DTU_PACKAGES[@]}"; do
        IFS=':' read -r pkg desc <<< "$pkg_info"
        run_subcheck "DTU" "$desc ($pkg)" "conda list | grep -q '^$pkg '" "pass"
    done
fi

# 5. JUPYTER/NOTEBOOK CHECKS
echo "📓 5. JUPYTER NOTEBOOKS"
echo "─────────────────────────"

if command -v conda > /dev/null; then
    run_subcheck "Jupyter" "Jupyter Lab Available" "conda list | grep -q '^jupyterlab '" "pass"
    run_subcheck "Jupyter" "Jupyter Notebook Available" "conda list | grep -q '^notebook '" "pass"
    run_subcheck "Jupyter" "IPython Kernel Available" "conda list | grep -q '^ipykernel '" "pass"
    
    # Check if jupyter command works
    run_subcheck "Jupyter" "Jupyter Command Functional" "command -v jupyter" "pass"
fi

# 6. DEVELOPMENT TOOLS
echo "🔧 6. DEVELOPMENT TOOLS"
echo "─────────────────────────"

if command -v conda > /dev/null; then
    run_subcheck "DevTools" "Pip Available in Conda" "conda list | grep -q '^pip '" "pass"
    run_subcheck "DevTools" "Git Available" "command -v git" "pass"
    run_subcheck "DevTools" "Pytest Available" "conda list | grep -q '^pytest '" "pass"
fi

# 7. ENVIRONMENT VARIABLES
echo "🔧 7. ENVIRONMENT CONFIGURATION"
echo "─────────────────────────────────"

run_subcheck "Config" "CONDA_DEFAULT_ENV Set" "[ -n \"${CONDA_DEFAULT_ENV:-}\" ]" "pass"
run_subcheck "Config" "PATH Contains Conda" "echo \$PATH | grep -q conda" "pass"

if [[ -f ~/.zshrc ]]; then
    run_subcheck "Config" "Conda Init in .zshrc" "grep -q 'conda initialize' ~/.zshrc" "pass"
fi

if [[ -f ~/.bashrc ]]; then
    run_subcheck "Config" "Conda Init in .bashrc" "grep -q 'conda initialize' ~/.bashrc" "pass"
fi

# SUMMARY
echo ""
echo "═══════════════════════════════════════"
echo "🎯 DIAGNOSTIC SUMMARY"
echo "═══════════════════════════════════════"
echo ""
echo "Total Subchecks: $TOTAL_SUBCHECKS"
echo "Passed: $PASSED_SUBCHECKS"
echo "Failed: $FAILED_SUBCHECKS"
echo ""

if [[ $FAILED_SUBCHECKS -gt 0 ]]; then
    echo "❌ Issues detected in Python/Conda environment"
    echo ""
    
    # Show failed subchecks
    echo "🔍 FAILED CHECKS:"
    for result in "${SUBCHECK_RESULTS[@]}"; do
        IFS='|' read -r cat name status output <<< "$result"
        if [[ "$status" == "FAIL" ]]; then
            echo "  ❌ $cat: $name"
            if [[ -n "$output" && ${#output} -lt 200 ]]; then
                echo "     → $output"
            fi
        fi
    done
    echo ""
    
    exit 1
else
    echo "✅ All Python/Conda checks passed!"
    echo "🎉 Environment is properly configured for DTU courses"
    echo ""
    exit 0
fi