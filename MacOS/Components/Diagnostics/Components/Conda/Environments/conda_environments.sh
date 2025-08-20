#!/bin/bash
# @name: Conda Environments Check
# @description: List and analyze Conda environments
# @category: Conda
# @subcategory: Environments
# @timeout: 15

echo "CONDA ENVIRONMENTS CHECK"
echo "========================"

# Check if conda is available
if ! command -v conda >/dev/null 2>&1; then
    echo "❌ Conda not found - cannot check environments"
    exit 1
fi

# Get conda info
echo "Conda Configuration:"
echo "-------------------"
if conda info > /dev/null 2>&1; then
    conda info | grep -E "(conda version|platform|python version|base environment|envs directories)" | sed 's/^/  /'
else
    echo "  Unable to get conda info"
    exit 1
fi

echo ""

# List environments
echo "Conda Environments:"
echo "------------------"
if conda env list > /dev/null 2>&1; then
    env_count=0
    active_env=""
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^#.* ]] || [[ -z "$line" ]]; then
            continue
        fi
        
        echo "  $line"
        env_count=$((env_count + 1))
        
        if [[ "$line" == *" * "* ]]; then
            active_env=$(echo "$line" | awk '{print $1}')
        fi
    done < <(conda env list 2>/dev/null)
    
    echo ""
    echo "Environment Summary:"
    echo "-------------------"
    echo "Total environments: $env_count"
    
    if [ -n "$active_env" ]; then
        echo "✓ Active environment: $active_env"
    else
        echo "✓ Active environment: base"
    fi
else
    echo "  Unable to list environments"
    exit 1
fi

echo ""

# Check conda environment variables
echo "Conda Environment Variables:"
echo "---------------------------"
if [ -n "${CONDA_DEFAULT_ENV:-}" ]; then
    echo "CONDA_DEFAULT_ENV: $CONDA_DEFAULT_ENV"
else
    echo "CONDA_DEFAULT_ENV: Not set"
fi

if [ -n "${CONDA_PREFIX:-}" ]; then
    echo "CONDA_PREFIX: $CONDA_PREFIX"
else
    echo "CONDA_PREFIX: Not set"
fi

if [ -n "${CONDA_SHLVL:-}" ]; then
    echo "CONDA_SHLVL: $CONDA_SHLVL"
else
    echo "CONDA_SHLVL: Not set"
fi

echo ""
echo "✅ Conda environments check complete - PASSED"