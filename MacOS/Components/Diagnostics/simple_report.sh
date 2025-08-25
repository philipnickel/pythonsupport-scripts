#!/bin/bash
# Simple Installation Report Generator

# Get system info
get_system_info() {
    echo "macOS $(sw_vers -productVersion) ($(sw_vers -productName))"
    echo "Architecture: $(uname -m)"
    echo "Date: $(date)"
}

# Run first year test and capture results
run_first_year_test() {
    if [ -f "$(dirname "$0")/first_year_test.sh" ]; then
        "$(dirname "$0")/first_year_test.sh" 2>&1
    else
        # Inline test if external script not found
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
    fi
}

# Generate HTML report
generate_html_report() {
    local output_file="/tmp/dtu_installation_report_$(date +%Y%m%d_%H%M%S).html"
    local timestamp=$(date)
    local system_info=$(get_system_info)
    local test_results=$(run_first_year_test)
    local install_log=""
    
    # Parse test results for summary counts (exclude header and overall result lines)
    local pass_count=$(echo "$test_results" | grep ": PASS$" | wc -l)
    local fail_count=$(echo "$test_results" | grep ": FAIL$" | wc -l)
    local total_count=$((pass_count + fail_count))
    
    # Read installation log if available
    if [ -n "$INSTALL_LOG" ] && [ -f "$INSTALL_LOG" ]; then
        install_log=$(cat "$INSTALL_LOG")
    else
        install_log="Installation log not available"
    fi
    
    cat > "$output_file" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DTU Python Installation Support - First Year</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #000000; background: #DADADA; padding: 20px; }
        .container { max-width: 1000px; margin: 0 auto; background: #ffffff; border: 1px solid #ccc; }
        
        header { background: #990000; color: #ffffff; padding: 30px; text-align: center; }
        .dtu-logo { height: 50px; margin-bottom: 15px; filter: brightness(0) invert(1); }
        h1 { font-size: 2em; margin-bottom: 10px; }
        .timestamp { font-size: 0.9em; }
        
        .summary { display: flex; justify-content: center; gap: 40px; padding: 20px; background: #f5f5f5; border-bottom: 1px solid #ccc; }
        .summary-item { text-align: center; }
        .summary-number { font-size: 2.5em; font-weight: bold; }
        .summary-label { color: #666; text-transform: uppercase; font-size: 0.8em; }
        .passed { color: #008835; }
        .failed { color: #E83F48; }
        .total { color: #990000; }
        
        .download-section { text-align: center; padding: 15px; background: #f5f5f5; border-bottom: 1px solid #ccc; }
        .download-button { padding: 10px 20px; border: 2px solid #990000; background: #ffffff; color: #990000; text-decoration: none; font-weight: bold; }
        .download-button:hover { background: #990000; color: #ffffff; }
        
        .notice { background: #fff3cd; border: 1px solid #ffc107; padding: 15px; margin: 20px; color: #856404; }
        .notice-title { font-weight: bold; margin-bottom: 5px; }
        
        .category-section { margin: 20px; border: 1px solid #ccc; }
        .category-header { font-size: 1.2em; font-weight: bold; color: #ffffff; padding: 15px; background: #990000; text-align: center; }
        .category-container { padding: 20px; }
        
        .expandable { cursor: pointer; }
        .expandable:hover { background: #e9ecef; }
        .expand-toggle { float: right; font-weight: bold; }
        .content { display: none; background: #f5f5f5; padding: 15px; font-family: monospace; white-space: pre-wrap; border: 1px solid #ccc; margin-top: 10px; }
        .content.expanded { display: block; }
        .test-results { background: #f5f5f5; padding: 15px; font-family: monospace; white-space: pre-wrap; border: 1px solid #ccc; }
        .system-info { background: #f5f5f5; padding: 15px; font-family: monospace; border: 1px solid #ccc; }
        .install-log { background: #f5f5f5; padding: 15px; font-family: monospace; white-space: pre-wrap; border: 1px solid #ccc; }
        
        footer { text-align: center; padding: 20px; background: #990000; color: #ffffff; }
        footer p { margin: 5px 0; }
        .footer-logo { height: 30px; margin: 10px 0; filter: brightness(0) invert(1); }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <img src="https://designguide.dtu.dk/-/media/subsites/designguide/design-basics/logo/dtu_logo_corporate_red_rgb.png" 
                 alt="DTU Logo" class="dtu-logo" onerror="this.style.display='none'">
            <h1>DTU Python Installation Support - First Year</h1>
            <div class="timestamp">Generated on: $timestamp</div>
        </header>
        
        <div class="summary">
            <div class="summary-item">
                <div class="summary-number passed">$pass_count</div>
                <div class="summary-label">Passed</div>
            </div>
            <div class="summary-item">
                <div class="summary-number failed">$fail_count</div>
                <div class="summary-label">Failed</div>
            </div>
            <div class="summary-item">
                <div class="summary-number total">$total_count</div>
                <div class="summary-label">Total Checks</div>
            </div>
        </div>
        
        <div class="download-section">
            <a href="mailto:pythonsupport@dtu.dk?subject=Installation%20Support&body=Please%20find%20my%20installation%20report%20attached." class="download-button">Email Support</a>
        </div>
        
        <div class="notice">
            <div class="notice-title">First Year Installation Diagnostics</div>
            This report shows the validation results for your DTU first year Python installation.
        </div>
        
        <div class="diagnostics">
            <div class="category-section">
                <div class="category-header expandable" onclick="toggleExpand('test-results')">
                    First Year Setup Validation <span class="expand-toggle" id="test-results-toggle">[+]</span>
                </div>
                <div class="category-container">
                    <div class="content" id="test-results">$test_results</div>
                </div>
            </div>
            
            <div class="category-section">
                <div class="category-header expandable" onclick="toggleExpand('system-info')">
                    System Information <span class="expand-toggle" id="system-info-toggle">[+]</span>
                </div>
                <div class="category-container">
                    <div class="content" id="system-info">$system_info</div>
                </div>
            </div>
            
            <div class="category-section">
                <div class="category-header expandable" onclick="toggleExpand('install-log')">
                    Installation Log <span class="expand-toggle" id="install-log-toggle">[+]</span>
                </div>
                <div class="category-container">
                    <div class="content" id="install-log">$install_log</div>
                </div>
            </div>
        </div>
        
        <script>
        function toggleExpand(id) {
            var content = document.getElementById(id);
            var toggle = document.getElementById(id + '-toggle');
            if (content.classList.contains('expanded')) {
                content.classList.remove('expanded');
                toggle.textContent = '[+]';
            } else {
                content.classList.add('expanded');
                toggle.textContent = '[-]';
            }
        }
        </script>
        
        <footer>
            <img src="https://designguide.dtu.dk/-/media/subsites/designguide/design-basics/logo/dtu_logo_corporate_red_rgb.png" 
                 alt="DTU Logo" class="footer-logo" onerror="this.style.display='none'">
            <p><strong>DTU Python Installation Support</strong></p>
            <p>Technical University of Denmark | Danmarks Tekniske Universitet</p>
        </footer>
    </div>
</body>
</html>
EOF

    echo "$output_file"
}

# Main execution
main() {
    echo "Generating installation report..."
    
    local report_file=$(generate_html_report)
    
    echo "Report generated: $report_file"
    
    # Open report in browser
    if command -v open >/dev/null 2>&1; then
        open "$report_file"
        echo "Report opened in browser"
    fi
}

main