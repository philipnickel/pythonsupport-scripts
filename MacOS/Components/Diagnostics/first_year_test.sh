#!/bin/bash
# Simple First Year Setup Test

test_first_year_setup() {
    echo "=== First Year Setup Test ==="
    
    local all_passed=true
    
    # Test Python 3.11
    echo -n "Python 3.11: "
    if python3 --version 2>/dev/null | grep -q "3.11"; then
        echo "PASS"
    else
        echo "FAIL"
        all_passed=false
    fi
    
    # Test VSCode
    echo -n "VS Code: "
    if command -v code >/dev/null 2>&1 && code --version >/dev/null 2>&1; then
        echo "PASS"
    else
        echo "FAIL"
        all_passed=false
    fi
    
    # Test Python packages
    echo -n "Python packages: "
    if python3 -c "import dtumathtools, pandas, scipy, statsmodels, uncertainties" 2>/dev/null; then
        echo "PASS"
    else
        echo "FAIL"
        all_passed=false
    fi
    
    # Test VSCode Python extension
    echo -n "VS Code Python extension: "
    if code --list-extensions 2>/dev/null | grep -q "ms-python.python"; then
        echo "PASS"
    else
        echo "FAIL" 
        all_passed=false
    fi
    
    echo ""
    if [ "$all_passed" = true ]; then
        echo "Overall Result: PASS - First year setup complete!"
        return 0
    else
        echo "Overall Result: FAIL - Some components missing"
        return 1
    fi
}

# Run test and return result
test_first_year_setup