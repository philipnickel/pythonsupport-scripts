#!/bin/bash
# Simple Installation Report Generator

# Exit codes for Piwik logging:
# 0 = All tests passed (complete success)
# 1 = Python Installation failed (Python 3.11)
# 2 = Python Environment failed (packages)
# 3 = VS Code Setup failed (VS Code + extension)
# 4 = Multiple categories failed
# 5 = Script error

# Get system info
get_system_info() {
    # Self-contained configuration - try external first, fall back to defaults
    REMOTE_PS=${REMOTE_PS:-"dtudk/pythonsupport-scripts"}
    BRANCH_PS=${BRANCH_PS:-"main"}
    
    CONFIG_URL="https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/config.sh"
    CONFIG_FILE="/tmp/sysinfo_config_$$.sh"
    if curl -fsSL "$CONFIG_URL" -o "$CONFIG_FILE" 2>/dev/null && [ -s "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        rm -f "$CONFIG_FILE"
    fi
    
    # Ensure we always have defaults
    PYTHON_VERSION_DTU=${PYTHON_VERSION_DTU:-"3.12"}
    if [ -z "${DTU_PACKAGES[*]:-}" ]; then
        DTU_PACKAGES=("dtumathtools" "pandas" "scipy" "statsmodels" "uncertainties")
    fi
    
    echo "=== System Information ==="
    echo "Operating System: macOS $(sw_vers -productVersion) ($(sw_vers -productName))"
    echo "Build Version: $(sw_vers -buildVersion)"
    echo "Architecture: $(uname -m)"
    echo ""
    
    echo "=== Hardware Information ==="
    echo "Model: $(system_profiler SPHardwareDataType | grep "Model Name" | cut -d: -f2 | xargs)"
    echo "Processor: $(system_profiler SPHardwareDataType | grep "Chip" | cut -d: -f2 | xargs || system_profiler SPHardwareDataType | grep "Processor Name" | cut -d: -f2 | xargs)"
    echo "Memory: $(system_profiler SPHardwareDataType | grep "Memory" | cut -d: -f2 | xargs)"
    echo ""
    
    echo "=== Python Environment ==="
    if [ -f "$HOME/miniforge3/bin/activate" ]; then
        source "$HOME/miniforge3/bin/activate" 2>/dev/null || true
    fi
    echo "Python Location: $(which python3 2>/dev/null || echo 'Not found')"
    echo "Python Version: $(python3 --version 2>/dev/null || echo 'Not found')"
    echo "Conda Location: $(which conda 2>/dev/null || echo 'Not found')"
    echo "Conda Version: $(conda --version 2>/dev/null || echo 'Not found')"
    echo "Conda Base: $(conda info --base 2>/dev/null || echo 'Not found')"
    echo ""
    
    echo "=== DTU Configuration ==="
    echo "Expected Python Version: ${PYTHON_VERSION_DTU:-'Not loaded'}"
    echo "Required DTU Packages: ${DTU_PACKAGES[*]:-'Not loaded'}"
    echo ""
    
    echo "=== VS Code Environment ==="
    echo "VS Code Location: $(which code 2>/dev/null || echo 'Not found')"
    echo "VS Code Version: $(code --version 2>/dev/null | head -1 || echo 'Not found')"
    echo "Installed Extensions:"
    code --list-extensions 2>/dev/null | head -10 || echo "No extensions found"
}

# Run first year test - all 4 required verifications
run_first_year_test() {
    echo "=== First Year Setup Test ==="
    echo ""
    
    local miniforge_failed=false
    local python_failed=false
    local packages_failed=false
    local vscode_failed=false
    local extensions_failed=false
    
    # Test 1: Miniforge Installation
    echo "Testing Miniforge Installation..."
    if [ -d "$HOME/miniforge3" ] && command -v conda >/dev/null 2>&1; then
        echo "PASS: Miniforge installed at $HOME/miniforge3"
    else
        echo "FAIL: Miniforge not found or conda command not available"
        miniforge_failed=true
    fi
    echo ""
    
    # Test 2: Python Version (from miniforge)
    echo "Testing Python Version..."
    EXPECTED_VERSION="3.12"
    INSTALLED_VERSION=$(python3 --version 2>/dev/null | cut -d " " -f 2)
    PYTHON_PATH=$(which python3 2>/dev/null)
    if [[ "$INSTALLED_VERSION" == "$EXPECTED_VERSION"* ]] && [[ "$PYTHON_PATH" == *"miniforge3"* ]]; then
        echo "PASS: Python $INSTALLED_VERSION from miniforge"
    else
        echo "FAIL: Expected Python $EXPECTED_VERSION from miniforge, found $INSTALLED_VERSION at $PYTHON_PATH"
        python_failed=true
    fi
    echo ""
    
    # Test 3: DTU Packages
    echo "Testing DTU Packages..."
    if python3 -c "import dtumathtools, pandas, scipy, statsmodels, uncertainties; print('All packages imported successfully')" 2>/dev/null; then
        echo "PASS: All DTU packages imported successfully"
    else
        echo "FAIL: Some DTU packages failed to import"
        packages_failed=true
    fi
    echo ""
    
    # Test 4: VS Code
    echo "Testing VS Code..."
    if code --version >/dev/null 2>&1; then
        echo "PASS: VS Code $(code --version 2>/dev/null | head -1)"
    else
        echo "FAIL: VS Code not available"
        vscode_failed=true
    fi
    echo ""
    
    # Test 5: VS Code Extensions
    echo "Testing VS Code Extensions..."
    if code --list-extensions 2>/dev/null | grep -q "ms-python.python"; then
        echo "PASS: Python extension installed"
        if code --list-extensions 2>/dev/null | grep -q "ms-toolsai.jupyter"; then
            echo "PASS: Jupyter extension installed"  
        else
            echo "FAIL: Jupyter extension missing"
            extensions_failed=true
        fi
    else
        echo "FAIL: Python extension missing"
        extensions_failed=true
    fi
    
    echo ""
    echo "════════════════════════════════════════"
    
    # Overall result
    local fail_count=0
    if [ "$miniforge_failed" = true ]; then fail_count=$((fail_count + 1)); fi
    if [ "$python_failed" = true ]; then fail_count=$((fail_count + 1)); fi
    if [ "$packages_failed" = true ]; then fail_count=$((fail_count + 1)); fi  
    if [ "$vscode_failed" = true ]; then fail_count=$((fail_count + 1)); fi
    if [ "$extensions_failed" = true ]; then fail_count=$((fail_count + 1)); fi
    
    if [ $fail_count -eq 0 ]; then
        echo "OVERALL RESULT: PASS - All components working"
        return 0
    else
        echo "OVERALL RESULT: FAIL - $fail_count component(s) failed"
        return 1
    fi
}

# Generate HTML report
generate_html_report() {
    local output_file="/tmp/dtu_installation_report_$(date +%Y%m%d_%H%M%S).html"
    local timestamp=$(date)
    local system_info=$(get_system_info)
    local test_results=$(run_first_year_test 2>&1)
    local test_exit_code=$?
    local install_log=""
    
    # Parse test results for summary counts (exclude header and overall result lines)
    local pass_count=$(echo "$test_results" | grep "^PASS:" | wc -l)
    local fail_count=$(echo "$test_results" | grep "^FAIL:" | wc -l)
    local total_count=$((pass_count + fail_count))
    
    # Generate professional status message
    local status_message
    local status_class
    if [ $fail_count -eq 0 ] && [ $total_count -gt 0 ]; then
        status_message="Everything is set up and working correctly"
        status_class="status-success"
    elif [ $fail_count -eq 1 ]; then
        status_message="Setup is mostly complete with one issue to resolve"
        status_class="status-warning"
    elif [ $fail_count -gt 1 ]; then
        status_message="Several setup issues need to be resolved"
        status_class="status-error"
    else
        status_message="No tests completed"
        status_class="status-unknown"
    fi
    
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
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #000000; background: #DADADA; padding: 20px; margin: 0; }
        .container { max-width: 1000px; margin: 0 auto; background: #ffffff; border: 1px solid #ccc; }
        
        header { background: #990000; color: #ffffff; padding: 30px 20px; display: flex; align-items: center; gap: 25px; }
        .header-left { flex-shrink: 0; }
        .header-content { flex: 1; }
        .dtu-logo { height: 50px; filter: brightness(0) invert(1); }
        h1 { font-size: 1.9em; margin: 0; line-height: 1.2; font-weight: bold; }
        .subtitle { font-size: 1.2em; margin-top: 8px; opacity: 0.9; font-weight: normal; }
        .timestamp { font-size: 0.9em; margin-top: 12px; opacity: 0.8; }
        
        .summary { display: flex; justify-content: center; padding: 30px; background: #f5f5f5; border-bottom: 1px solid #ccc; }
        .status-message { text-align: center; }
        .status-text { font-size: 1.4em; font-weight: 600; margin-bottom: 5px; }
        .status-details { font-size: 0.9em; color: #666; }
        .status-success .status-text { color: #008835; }
        .status-warning .status-text { color: #f57c00; }
        .status-error .status-text { color: #E83F48; }
        .status-unknown .status-text { color: #666; }
        .passed { color: #008835; }
        .failed { color: #E83F48; }
        .total { color: #990000; }
        
        .download-section { text-align: center; padding: 15px; background: #f5f5f5; border-bottom: 1px solid #ccc; }
        .download-button { padding: 12px 24px; border: 2px solid #990000; background: #ffffff; color: #990000; text-decoration: none; font-weight: bold; border-radius: 4px; cursor: pointer; transition: all 0.3s; font-size: 1em; }
        .download-button:hover { background: #990000; color: #ffffff; transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.1); }
        
        /* Modal Styles */
        .modal { display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; background-color: rgba(0,0,0,0.5); }
        .modal-content { background-color: #fefefe; margin: 5% auto; padding: 0; border: none; width: 90%; max-width: 600px; border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); animation: slideIn 0.3s ease-out; }
        @keyframes slideIn { from { opacity: 0; transform: translateY(-50px); } to { opacity: 1; transform: translateY(0); } }
        .modal-header { background: #990000; color: white; padding: 20px; border-radius: 8px 8px 0 0; }
        .modal-header h2 { margin: 0; font-size: 1.4em; }
        .close { float: right; font-size: 28px; font-weight: bold; cursor: pointer; line-height: 1; }
        .close:hover { opacity: 0.7; }
        .modal-body { padding: 30px; }
        .step { display: flex; align-items: flex-start; margin-bottom: 25px; padding: 20px; background: #f8f9fa; border-radius: 6px; border-left: 4px solid #990000; }
        .step-number { background: #990000; color: white; width: 30px; height: 30px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: bold; margin-right: 15px; flex-shrink: 0; }
        .step-content { flex: 1; }
        .step-title { font-weight: bold; color: #333; margin-bottom: 8px; font-size: 1.1em; }
        .step-description { color: #666; line-height: 1.5; }
        .action-button { background: #990000; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; font-weight: bold; margin-top: 10px; transition: all 0.3s; }
        .action-button:hover { background: #b30000; transform: translateY(-1px); }
        
        .notice { background: #fff3cd; border: 1px solid #ffc107; padding: 15px; margin: 20px; color: #856404; }
        .notice-title { font-weight: bold; margin-bottom: 5px; }
        
        .category-section { 
            margin: 20px 0; 
            padding: 0 20px;
        }
        
        .category-header { 
            font-size: 1.3em; 
            font-weight: bold; 
            color: #990000; 
            padding: 15px 0; 
            border-bottom: 2px solid #990000; 
            margin-bottom: 15px;
        }
        
        .category-container { 
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        
        .diagnostic-card {
            background: white;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            overflow: hidden;
            transition: all 0.3s;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }
        
        .diagnostic-card:hover {
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            transform: translateY(-2px);
        }
        
        .diagnostic-header {
            padding: 12px 16px;
            cursor: pointer;
            user-select: none;
            background: #f8f9fa;
            transition: background-color 0.3s;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .diagnostic-header:hover {
            background: #e9ecef;
        }
        
        .diagnostic-info {
            display: flex;
            flex-direction: column;
            flex: 1;
        }
        
        .diagnostic-name {
            font-weight: 600;
            font-size: 1.1em;
            color: #333;
        }
        
        .diagnostic-expand-hint {
            font-size: 0.85em;
            color: #666;
            margin-top: 2px;
        }
        
        .diagnostic-details {
            display: none;
            background: #f8f9fa;
            padding: 16px;
            border-top: 1px solid #dee2e6;
        }
        
        .diagnostic-card.expanded .diagnostic-details {
            display: block;
            animation: slideDown 0.3s ease-out;
        }
        
        .diagnostic-log {
            font-family: 'SF Mono', 'Monaco', 'Inconsolata', 'Fira Code', monospace;
            white-space: pre-wrap;
            line-height: 1.4;
            font-size: 0.9em;
            color: #333;
            max-height: 400px;
            overflow-y: auto;
        }
        
        @keyframes slideDown {
            from {
                opacity: 0;
                transform: translateY(-10px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
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
            <div class="header-left">
                <img src="https://designguide.dtu.dk/-/media/subsites/designguide/design-basics/logo/dtu_logo_corporate_red_rgb.png" 
                     alt="DTU Logo" class="dtu-logo" onerror="this.style.display='none'">
            </div>
            <div class="header-content">
                <h1>DTU Python Installation Support</h1>
                <div class="subtitle">Installation Summary</div>
                <div class="timestamp">Generated on: $timestamp</div>
            </div>
        </header>
        
        <div class="summary">
            <div class="status-message $status_class">
                <div class="status-text">$status_message</div>
                <div class="status-details">$pass_count of $total_count components working properly</div>
            </div>
        </div>
        
        <div class="download-section">
            <button onclick="showEmailModal()" class="download-button">Email Support</button>
        </div>
        
        <!-- Email Support Modal -->
        <div id="emailModal" class="modal">
            <div class="modal-content">
                <div class="modal-header">
                    <span class="close" onclick="closeEmailModal()">&times;</span>
                    <h2>Email Support Instructions</h2>
                </div>
                <div class="modal-body">
                    <div class="step">
                        <div class="step-number">1</div>
                        <div class="step-content">
                            <div class="step-title">Download Report</div>
                            <div class="step-description">Click the button below to download this diagnostic report to your computer. You'll need this file for the next step.</div>
                            <button onclick="downloadReport()" class="action-button">Download Report</button>
                        </div>
                    </div>
                    <div class="step">
                        <div class="step-number">2</div>
                        <div class="step-content">
                            <div class="step-title">Send Email</div>
                            <div class="step-description">Click below to open your email client with a pre-filled message to DTU Python Support. Attach the downloaded report file from Step 1.</div>
                            <button onclick="openEmail()" class="action-button">Open Email Client</button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="notice">
            <div class="notice-title">First Year Installation Diagnostics</div>
            This report shows the validation results for your DTU first year Python installation.
        </div>
        
        <div class="diagnostics">
            <div class="category-section">
                <div class="category-header">First Year Setup Validation</div>
                <div class="category-container">
                    <div class="diagnostic-card" onclick="toggleCard(this)">
                        <div class="diagnostic-header">
                            <div class="diagnostic-info">
                                <div class="diagnostic-name">Test Results</div>
                                <div class="diagnostic-expand-hint">Click to expand</div>
                            </div>
                        </div>
                        <div class="diagnostic-details">
                            <div class="diagnostic-log">$test_results</div>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="category-section">
                <div class="category-header">System Information</div>
                <div class="category-container">
                    <div class="diagnostic-card" onclick="toggleCard(this)">
                        <div class="diagnostic-header">
                            <div class="diagnostic-info">
                                <div class="diagnostic-name">System Details</div>
                                <div class="diagnostic-expand-hint">Click to expand</div>
                            </div>
                        </div>
                        <div class="diagnostic-details">
                            <div class="diagnostic-log">$system_info</div>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="category-section">
                <div class="category-header">Installation Log</div>
                <div class="category-container">
                    <div class="diagnostic-card" onclick="toggleCard(this)">
                        <div class="diagnostic-header">
                            <div class="diagnostic-info">
                                <div class="diagnostic-name">Complete Installation Output</div>
                                <div class="diagnostic-expand-hint">Click to expand</div>
                            </div>
                        </div>
                        <div class="diagnostic-details">
                            <div class="diagnostic-log">$install_log</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <script>
        function toggleCard(card) {
            card.classList.toggle('expanded');
        }
        
        function showEmailModal() {
            document.getElementById('emailModal').style.display = 'block';
        }
        
        function closeEmailModal() {
            document.getElementById('emailModal').style.display = 'none';
        }
        
        function downloadReport() {
            const reportContent = document.documentElement.outerHTML;
            const blob = new Blob([reportContent], { type: 'text/html' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'DTU_Python_Installation_Report_' + new Date().toISOString().slice(0,10) + '.html';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        }
        
        function openEmail() {
            const subject = encodeURIComponent('DTU Python Installation Support Request');
            const body = encodeURIComponent('Python environment setup issue\\n\\nCourse: [PLEASE FILL OUT]\\n\\nDiagnostic report attached.\\n\\nComponents:\\n' + 
                '• Python: ' + (document.querySelector('.diagnostic-log').textContent.includes('PASS: Python') ? 'Working' : 'Issue') + '\\n' +
                '• Packages: ' + (document.querySelector('.diagnostic-log').textContent.includes('PASS: Python Environment') ? 'Working' : 'Issue') + '\\n' +
                '• VS Code: ' + (document.querySelector('.diagnostic-log').textContent.includes('PASS: VS Code') ? 'Working' : 'Issue') + '\\n\\n' +
                'Additional notes:\\nIf you have any additional notes\\n\\nThanks');
            
            window.location.href = 'mailto:pythonsupport@dtu.dk?subject=' + subject + '&body=' + body;
            closeEmailModal();
        }
        
        // Close modal when clicking outside of it
        window.onclick = function(event) {
            const modal = document.getElementById('emailModal');
            if (event.target == modal) {
                closeEmailModal();
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
    return $test_exit_code
}

# Main execution
main() {
    echo "Generating installation report..."
    
    local report_file
    report_file=$(generate_html_report)
    local exit_code=$?
    
    echo "Report generated: $report_file"
    
    # Open report in browser
    if command -v open >/dev/null 2>&1; then
        open "$report_file"
        echo "Report opened in browser"
    fi
    
    # Return the test exit code for Piwik logging
    return $exit_code
}

# Only run main if script is executed directly (not sourced)  
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi