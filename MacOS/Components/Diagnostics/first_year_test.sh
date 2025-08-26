#!/bin/bash
# DTU First Year Setup Test - Self-contained version

test_first_year_setup() {
    echo "=== First Year Setup Test ==="
    echo ""
    
    # Self-contained configuration
    PYTHON_VERSION_DTU=${PYTHON_VERSION_DTU:-"3.12"}
    DTU_PACKAGES=${DTU_PACKAGES:-("dtumathtools" "pandas" "scipy" "statsmodels" "uncertainties")}
    
    local python_installation_failed=false
    local python_environment_failed=false
    local vscode_setup_failed=false
    local test_results=""
    
    # Test Python Installation
    echo "Testing Python Installation ($PYTHON_VERSION_DTU)..."
    if python3 --version 2>/dev/null | grep -q "$PYTHON_VERSION_DTU"; then
        echo "PASS: Python Installation ($PYTHON_VERSION_DTU): PASS"
        test_results="${test_results}PASS: Python Installation ($PYTHON_VERSION_DTU): PASS\n"
    else
        actual_version=$(python3 --version 2>/dev/null || echo 'Not found')
        echo "FAIL: Python Installation ($PYTHON_VERSION_DTU): FAIL (Found: $actual_version)"
        test_results="${test_results}FAIL: Python Installation ($PYTHON_VERSION_DTU): FAIL (Found: $actual_version)\n"
        python_installation_failed=true
    fi
    echo ""
    
    # Test Python Environment (packages)
    echo "Testing Python Environment (packages)..."
    package_imports=""
    for pkg in "${DTU_PACKAGES[@]}"; do
        if [ -z "$package_imports" ]; then
            package_imports="$pkg"
        else
            package_imports="$package_imports, $pkg"
        fi
    done
    
    if python3 -c "import $package_imports" 2>/dev/null; then
        echo "PASS: Python Environment (packages): PASS"
        test_results="${test_results}PASS: Python Environment (packages): PASS\n   All required packages installed: ${DTU_PACKAGES[*]}\n"
    else
        echo "FAIL: Python Environment (packages): FAIL"
        test_results="${test_results}FAIL: Python Environment (packages): FAIL\n   Required packages: ${DTU_PACKAGES[*]}\n"
        python_environment_failed=true
    fi
    echo ""
    
    # Test VS Code Setup
    echo "Testing VS Code Setup..."
    if command -v code >/dev/null 2>&1 && code --version >/dev/null 2>&1 && code --list-extensions 2>/dev/null | grep -q "ms-python.python"; then
        echo "PASS: VS Code Setup: PASS"
        test_results="${test_results}PASS: VS Code Setup: PASS\n   VS Code and Python extension are installed\n"
    else
        echo "FAIL: VS Code Setup: FAIL"
        test_results="${test_results}FAIL: VS Code Setup: FAIL\n   Missing VS Code or Python extension\n"
        vscode_setup_failed=true
    fi
    
    echo ""
    echo "════════════════════════════════════════"
    
    # Determine final result
    local failure_count=0
    if [ "$python_installation_failed" = true ]; then
        failure_count=$((failure_count + 1))
    fi
    if [ "$python_environment_failed" = true ]; then
        failure_count=$((failure_count + 1))
    fi
    if [ "$vscode_setup_failed" = true ]; then
        failure_count=$((failure_count + 1))
    fi
    
    if [ $failure_count -eq 0 ]; then
        echo "OVERALL RESULT: PASS"
        echo "   First year setup is complete and working!"
        test_results="${test_results}\nOVERALL RESULT: PASS\n   First year setup is complete and working!\n"
        return 0
    elif [ $failure_count -eq 1 ]; then
        if [ "$python_installation_failed" = true ]; then
            echo "OVERALL RESULT: FAIL - Python Installation Issue"
            test_results="${test_results}\nOVERALL RESULT: FAIL - Python Installation Issue\n"
            return 1
        elif [ "$python_environment_failed" = true ]; then
            echo "OVERALL RESULT: FAIL - Python Environment Issue"
            test_results="${test_results}\nOVERALL RESULT: FAIL - Python Environment Issue\n"
            return 2
        elif [ "$vscode_setup_failed" = true ]; then
            echo "OVERALL RESULT: FAIL - VS Code Setup Issue"
            test_results="${test_results}\nOVERALL RESULT: FAIL - VS Code Setup Issue\n"
            return 3
        fi
    else
        echo "OVERALL RESULT: FAIL - Multiple Issues Found"
        echo "   Please check the individual test results above."
        test_results="${test_results}\nOVERALL RESULT: FAIL - Multiple Issues Found\n   Please check the individual test results above.\n"
        return 4
    fi
}

# Run test and return result
test_first_year_setup