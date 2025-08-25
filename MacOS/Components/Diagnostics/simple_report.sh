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
    # Load configuration for system info display
    if [ -n "${REMOTE_PS:-}" ] && [ -n "${BRANCH_PS:-}" ]; then
        CONFIG_URL="https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/config.sh"
        CONFIG_FILE="/tmp/sysinfo_config_$$.sh"
        if curl -fsSL "$CONFIG_URL" -o "$CONFIG_FILE" 2>/dev/null && [ -s "$CONFIG_FILE" ]; then
            source "$CONFIG_FILE" 2>/dev/null || true
            rm -f "$CONFIG_FILE"
        fi
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

# Run first year test and capture results
run_first_year_test() {
    if [ -f "$(dirname "$0")/first_year_test.sh" ]; then
        local test_output
        test_output=$("$(dirname "$0")/first_year_test.sh" 2>&1)
        local test_exit_code=$?
        echo "$test_output"
        return $test_exit_code
    else
        # Inline test if external script not found
        echo "=== First Year Setup Test ==="
        echo ""
        
        local python_installation_failed=false
        local python_environment_failed=false
        local vscode_setup_failed=false
        local test_results=""
        
        # Load configuration for consistent version/package testing
        if [ -n "${REMOTE_PS:-}" ] && [ -n "${BRANCH_PS:-}" ]; then
            CONFIG_URL="https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/config.sh"
            CONFIG_FILE="/tmp/test_config_$$.sh"
            if curl -fsSL "$CONFIG_URL" -o "$CONFIG_FILE" 2>/dev/null && [ -s "$CONFIG_FILE" ]; then
                source "$CONFIG_FILE" 2>/dev/null || true
                rm -f "$CONFIG_FILE"
            fi
        fi
        
        # Set defaults if config loading failed
        PYTHON_VERSION_DTU=${PYTHON_VERSION_DTU:-"3.11"}
        DTU_PACKAGES=${DTU_PACKAGES:-("dtumathtools" "pandas" "scipy" "statsmodels" "uncertainties")}
        
        # Activate conda environment for tests and reload shell profiles
        if [ -f "$HOME/miniforge3/bin/activate" ]; then
            source "$HOME/miniforge3/bin/activate" 2>/dev/null || true
        fi
        
        # Reload shell profiles to ensure conda is in PATH
        [ -e ~/.bashrc ] && source ~/.bashrc 2>/dev/null || true
        [ -e ~/.bash_profile ] && source ~/.bash_profile 2>/dev/null || true
        [ -e ~/.zshrc ] && source ~/.zshrc 2>/dev/null || true
        
        # Update PATH to include conda
        export PATH="$HOME/miniforge3/bin:$PATH"
        
        # Test Python Installation (using config version)
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
        
        # Test Python Environment (using config packages)
        echo "Testing Python Environment (packages)..."
        # Convert package array to import string
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
        
        # Test VS Code Setup (VS Code + extension)
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
        
        # Export test results for post_install.sh to use
        export PYTHON_INSTALLATION_PASSED=$([ "$python_installation_failed" = false ] && echo "true" || echo "false")
        export PYTHON_ENVIRONMENT_PASSED=$([ "$python_environment_failed" = false ] && echo "true" || echo "false")
        export VSCODE_SETUP_PASSED=$([ "$vscode_setup_failed" = false ] && echo "true" || echo "false")
        
        # Determine exit code based on failures
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
        
        echo "════════════════════════════════════════"
        if [ $failure_count -eq 0 ]; then
            echo "OVERALL RESULT: PASS"
            echo "   First year setup is complete and working!"
            test_results="${test_results}\nOVERALL RESULT: PASS\n   First year setup is complete and working!\n"
            return 0  # All tests passed
        elif [ $failure_count -eq 1 ]; then
            # Single category failure - return specific code
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
            # Multiple failures
            echo "OVERALL RESULT: FAIL - Multiple Issues Found"
            echo "   Please check the individual test results above."
            test_results="${test_results}\nOVERALL RESULT: FAIL - Multiple Issues Found\n   Please check the individual test results above.\n"
            return 4
        fi
    fi
}

# Generate HTML report
generate_html_report() {
    local output_file="/tmp/dtu_installation_report_$(date +%Y%m%d_%H%M%S).html"
    local timestamp=$(date)
    local system_info=$(get_system_info)
    local test_results=$(run_first_year_test)
    local test_exit_code=$?
    local install_log=""
    
    # Parse test results for summary counts (exclude header and overall result lines)
    local pass_count=$(echo "$test_results" | grep ": PASS$" | wc -l)
    local fail_count=$(echo "$test_results" | grep ": FAIL$" | wc -l)
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
    exit $exit_code
}

main