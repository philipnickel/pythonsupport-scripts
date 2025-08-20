#!/bin/bash
# @doc
# @name: Component-Based System Diagnostics
# @description: Runs individual diagnostic components and generates a comprehensive summary
# @category: Diagnostics
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Diagnostics/run_components.sh)"
# @requirements: macOS system
# @notes: Runs each diagnostic component separately and compiles results
# @/doc

_prefix="PYS:"

echo "$_prefix Running Component-Based Python Support Diagnostics"
echo "$_prefix System analysis starting..."
echo "$_prefix Checking system compatibility..."
echo "========================================="
echo ""

# Define components and their scripts
components=(
    "System Information:system_info.sh"
    "Homebrew:homebrew_check.sh"
    "Python/Conda:python_conda_check.sh"
    "Visual Studio Code:vscode_check.sh"
    "LaTeX:latex_check.sh"
    "Environment:environment_check.sh"
)

# Initialize results arrays
results=()
status_codes=()
outputs=()

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENTS_DIR="$SCRIPT_DIR/Components"

# Run each component
for component_entry in "${components[@]}"; do
    IFS=':' read -r component_name script_name <<< "$component_entry"
    script_path="$COMPONENTS_DIR/$script_name"
    
    echo "Running $component_name diagnostics..."
    
    if [ -f "$script_path" ]; then
        # Make script executable
        chmod +x "$script_path"
        
        # Run the component script and capture output and exit code
        output=$(bash "$script_path" 2>&1)
        exit_code=$?
        
        # Store results
        results+=("$component_name:✓ Passed")
        status_codes+=("$component_name:$exit_code")
        outputs+=("$component_name:$output")
        
        # Determine status based on exit code
        case $exit_code in
            0)
                results[${#results[@]}-1]="$component_name:✓ Passed"
                ;;
            1)
                results[${#results[@]}-1]="$component_name:⚠ Warning"
                ;;
            *)
                results[${#results[@]}-1]="$component_name:✗ Failed"
                ;;
        esac
        
        echo "  Status: ${results[${#results[@]}-1]#*:}"
    else
        echo "  Error: Component script not found: $script_path"
        results+=("$component_name:✗ Error")
        status_codes+=("$component_name:3")
        outputs+=("$component_name:Component script not found")
    fi
    
    echo ""
done

# Generate summary
echo "========================================="
echo "DIAGNOSTIC SUMMARY"
echo "=================="

total_components=${#components[@]}
passed_components=0
warning_components=0
failed_components=0

for result_entry in "${results[@]}"; do
    IFS=':' read -r component_name status <<< "$result_entry"
    echo "$status - $component_name"
    
    case $status in
        "✓ Passed")
            ((passed_components++))
            ;;
        "⚠ Warning")
            ((warning_components++))
            ;;
        "✗ Failed"|"✗ Error")
            ((failed_components++))
            ;;
    esac
done

echo ""
echo "SUMMARY STATISTICS"
echo "=================="
echo "Total Components: $total_components"
echo "✓ Passed: $passed_components"
echo "⚠ Warnings: $warning_components"
echo "✗ Failed: $failed_components"
echo ""

# Overall assessment
if [ $failed_components -eq 0 ] && [ $warning_components -eq 0 ]; then
    echo "🎉 Your system is ready for Python development!"
    overall_status=0
elif [ $failed_components -eq 0 ]; then
    echo "⚠ Your system is mostly ready, but some improvements are recommended."
    overall_status=1
else
    echo "❌ Your system needs setup before Python development."
    overall_status=2
fi

echo ""
echo "========================================="
echo "$_prefix Component-based diagnostics complete"
echo ""

# Save detailed results to a file for potential export
REPORT_FILE="/tmp/dtu_python_diagnostics_$(date +%Y%m%d_%H%M%S).txt"

{
    echo "DTU First Year Python Diagnostics Report"
    echo "Generated: $(date)"
    echo "========================================="
    echo ""
    echo "SUMMARY"
    echo "======="
    echo "Total Components: $total_components"
    echo "✓ Passed: $passed_components"
    echo "⚠ Warnings: $warning_components"
    echo "✗ Failed: $failed_components"
    echo ""
    
    if [ $failed_components -eq 0 ] && [ $warning_components -eq 0 ]; then
        echo "🎉 Your system is ready for Python development!"
    elif [ $failed_components -eq 0 ]; then
        echo "⚠ Your system is mostly ready, but some improvements are recommended."
    else
        echo "❌ Your system needs setup before Python development."
    fi
    
    echo ""
    echo "DETAILED RESULTS"
    echo "================"
    
    for output_entry in "${outputs[@]}"; do
        IFS=':' read -r component_name output <<< "$output_entry"
        echo "=== $component_name ==="
        
        # Find corresponding status
        status=""
        for result_entry in "${results[@]}"; do
            IFS=':' read -r result_component result_status <<< "$result_entry"
            if [ "$result_component" = "$component_name" ]; then
                status="$result_status"
                break
            fi
        done
        
        echo "Status: $status"
        echo "Details:"
        echo "$output"
        echo ""
    done
} > "$REPORT_FILE"

echo "Detailed report saved to: $REPORT_FILE"
echo ""

exit $overall_status
