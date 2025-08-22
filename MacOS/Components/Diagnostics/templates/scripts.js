// Embedded diagnostic data (base64 encoded logs)
const diagnosticData = {{DIAGNOSTIC_DATA}};

// Initialize report
document.addEventListener('DOMContentLoaded', function() {
    // Set timestamp
    document.getElementById('timestamp').textContent = new Date().toLocaleString();
    
    // Organize data by categories and subcategories
    const categories = {};
    let passed = 0;
    let failed = 0;
    let timeout = 0;
    
    for (const [key, data] of Object.entries(diagnosticData)) {
        if (data.status === 'PASS') passed++;
        else if (data.status === 'TIMEOUT') timeout++;
        else failed++;
        
        const categoryKey = data.category;
        const subcategoryKey = data.subcategory || 'General';
        
        if (!categories[categoryKey]) {
            categories[categoryKey] = {};
        }
        if (!categories[categoryKey][subcategoryKey]) {
            categories[categoryKey][subcategoryKey] = [];
        }
        categories[categoryKey][subcategoryKey].push({key, ...data});
    }
    
    // Generate diagnostic cards
    generateDiagnosticCards(categories);
    
    // Update summary
    document.getElementById('passed-count').textContent = passed;
    document.getElementById('failed-count').textContent = failed;
    document.getElementById('timeout-count').textContent = timeout;
    document.getElementById('total-count').textContent = passed + failed + timeout;
});


function generateDiagnosticCards(categories) {
    const container = document.getElementById('diagnostics-container');
    
    // Create sections for each category and subcategory
    for (const [categoryName, subcategories] of Object.entries(categories)) {
        // Create category section
        const categorySection = document.createElement('div');
        categorySection.className = 'category-section';
        
        // Create category header
        const categoryHeader = document.createElement('div');
        categoryHeader.className = 'category-header';
        categoryHeader.textContent = categoryName;
        categorySection.appendChild(categoryHeader);
        
        // Create container for subcategories
        const categoryContainer = document.createElement('div');
        categoryContainer.className = 'category-container';
        
        // Process each subcategory
        for (const [subcategoryName, items] of Object.entries(subcategories)) {
            // Create subcategory header if there are multiple subcategories
            if (Object.keys(subcategories).length > 1) {
                const subcategoryHeader = document.createElement('div');
                subcategoryHeader.className = 'subcategory-header';
                subcategoryHeader.textContent = subcategoryName;
                categoryContainer.appendChild(subcategoryHeader);
            }
            
            // Create tests container for this subcategory
            const testsContainer = document.createElement('div');
            testsContainer.className = 'category-tests';
            
            // Create cards for items in this subcategory
            items.forEach(item => {
                // Decode log data
                let logContent = '';
                try {
                    logContent = item.log ? atob(item.log) : 'No log data available';
                } catch (e) {
                    logContent = 'Error decoding log data';
                }
                
                // No manual command extraction needed
                
                // Create diagnostic card
                const card = document.createElement('div');
                card.className = 'diagnostic-card';
                card.id = `item-${item.key}`;
                
                // No copy button needed
                
                card.innerHTML = `
                    <div class="diagnostic-header" onclick="toggleDetails(this)">
                        <div class="diagnostic-info">
                            <div class="diagnostic-name">${item.name}</div>
                            <div class="diagnostic-expand-hint">Click to expand</div>
                        </div>
                        <div class="diagnostic-status-section">
                            <span class="diagnostic-status status-${item.status.toLowerCase()}">
                                ${item.status}
                            </span>
                        </div>
                    </div>
                    <div class="diagnostic-details">
                        <div class="diagnostic-log">${escapeHtml(logContent)}</div>
                    </div>
                `;
                
                testsContainer.appendChild(card);
            });
            
            categoryContainer.appendChild(testsContainer);
        }
        
        categorySection.appendChild(categoryContainer);
        container.appendChild(categorySection);
    }
}


function toggleDetails(header) {
    const card = header.parentElement;
    card.classList.toggle('expanded');
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}


function emailSupport() {
    // Generate comprehensive summary for email
    const emailContent = generateComprehensiveEmailContent();
    
    // Create email content with detailed test output and system information
    const subject = 'DTU Python Installation Support - Diagnostic Report';
    const body = `I've run the DTU Python Installation verification and need assistance. Please see the diagnostic details below:

${emailContent.summary}

=== SYSTEM INFORMATION ===
${emailContent.systemInfo}

=== DETAILED TEST RESULTS ===
${emailContent.detailedResults}

${emailContent.failedTests.length > 0 ? `
=== FAILED TESTS LOG OUTPUT ===
${emailContent.failedTests}` : ''}

Please help me resolve any issues found in the diagnostic report.

Best regards,
[Your Name]
[Your Student ID / Email]

---
This diagnostic report was generated automatically by the DTU Python Installation Support system.
Report generated: ${new Date().toLocaleString()}
Browser: ${navigator.userAgent}`;

    // Create mailto link
    const mailtoLink = `mailto:pythonsupport@dtu.dk?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
    
    // Try to open email client
    window.location.href = mailtoLink;
}

function downloadReport() {
    // Get the current HTML content
    const htmlContent = document.documentElement.outerHTML;
    
    // Create a blob with the HTML content
    const blob = new Blob([htmlContent], { type: 'text/html' });
    
    // Create a download link
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = `DTU_Python_Diagnostics_${new Date().toISOString().slice(0,19).replace(/:/g, '-')}.html`;
    
    // Trigger the download
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    
    // Clean up the URL object
    URL.revokeObjectURL(link.href);
}

function generateComprehensiveEmailContent() {
    let passed = 0, failed = 0, timeout = 0;
    const detailedResults = [];
    const failedTestsWithLogs = [];
    let systemInfo = 'System information not available';
    
    // Get system information if available
    if (diagnosticData._system_info && diagnosticData._system_info.log) {
        try {
            systemInfo = atob(diagnosticData._system_info.log);
        } catch (e) {
            if (diagnosticData._system_info.systemInfo) {
                systemInfo = diagnosticData._system_info.systemInfo;
            }
        }
    } else if (diagnosticData._system_info && diagnosticData._system_info.systemInfo) {
        systemInfo = diagnosticData._system_info.systemInfo;
    }
    
    // Process all diagnostic data
    for (const [key, data] of Object.entries(diagnosticData)) {
        // Skip system info entry
        if (key === '_system_info') continue;
        
        // Decode log content
        let logContent = '';
        try {
            logContent = data.log ? atob(data.log) : 'No log data available';
        } catch (e) {
            logContent = 'Error decoding log data';
        }
        
        if (data.status === 'PASS') {
            passed++;
            detailedResults.push(`✓ PASSED - ${data.name}
   Category: ${data.category}${data.subcategory ? ` > ${data.subcategory}` : ''}
   Output: ${logContent.substring(0, 200)}${logContent.length > 200 ? '...' : ''}
`);
        } else if (data.status === 'TIMEOUT') {
            timeout++;
            detailedResults.push(`⚠ TIMEOUT - ${data.name}
   Category: ${data.category}${data.subcategory ? ` > ${data.subcategory}` : ''}
   Output: ${logContent.substring(0, 200)}${logContent.length > 200 ? '...' : ''}
`);
            failedTestsWithLogs.push(`--- ${data.name} (TIMEOUT) ---
Category: ${data.category}${data.subcategory ? ` > ${data.subcategory}` : ''}
Full Output:
${logContent}

`);
        } else if (data.status === 'FAIL') {
            failed++;
            detailedResults.push(`✗ FAILED - ${data.name}
   Category: ${data.category}${data.subcategory ? ` > ${data.subcategory}` : ''}
   Output: ${logContent.substring(0, 200)}${logContent.length > 200 ? '...' : ''}
`);
            failedTestsWithLogs.push(`--- ${data.name} (FAILED) ---
Category: ${data.category}${data.subcategory ? ` > ${data.subcategory}` : ''}
Full Output:
${logContent}

`);
        }
    }
    
    const summary = `Total Diagnostics: ${passed + failed + timeout}
Passed: ${passed}
Failed: ${failed}
Timeout: ${timeout}`;
    
    return {
        summary,
        systemInfo,
        detailedResults: detailedResults.join('\n'),
        failedTests: failedTestsWithLogs.join('\n')
    };
}

// Keep the original function for backward compatibility
function generateEmailSummary() {
    const comprehensive = generateComprehensiveEmailContent();
    return {
        summary: comprehensive.summary,
        failures: '',
        verboseReport: comprehensive.systemInfo + '\n=== DIAGNOSTIC RESULTS ===\n' + comprehensive.detailedResults
    };
}

function copyToClipboard(command, button) {
    // Try to use the Clipboard API first
    if (navigator.clipboard) {
        navigator.clipboard.writeText(command).then(function() {
            showCopyFeedback(button, true);
        }, function() {
            // Fallback to execCommand
            copyToClipboardFallback(command, button);
        });
    } else {
        copyToClipboardFallback(command, button);
    }
}

function copyToClipboardFallback(command, button) {
    // Create a temporary textarea element
    const textarea = document.createElement('textarea');
    textarea.value = command;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    
    try {
        textarea.select();
        const successful = document.execCommand('copy');
        showCopyFeedback(button, successful);
    } catch (err) {
        showCopyFeedback(button, false);
    }
    
    document.body.removeChild(textarea);
}

function showCopyFeedback(button, success) {
    const originalContent = button.innerHTML;
    const originalColor = button.style.color;
    const originalBackground = button.style.background;
    
    if (success) {
        button.innerHTML = '✓';
        button.style.background = '#d4edda';
        button.style.color = '#155724';
        button.style.borderColor = '#c3e6cb';
    } else {
        button.innerHTML = '✗';
        button.style.background = '#f8d7da';
        button.style.color = '#721c24';
        button.style.borderColor = '#f5c6cb';
    }
    
    setTimeout(() => {
        button.innerHTML = originalContent;
        button.style.background = originalBackground;
        button.style.color = originalColor;
        button.style.borderColor = '';
    }, 2000);
}