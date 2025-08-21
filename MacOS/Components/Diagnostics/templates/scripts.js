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
    // Generate summary for email
    const summaryData = generateEmailSummary();
    
    // Create email content
    const subject = 'DTU Python Support - Diagnostic Report';
    const body = `Hello DTU Python Support Team,

I've run the diagnostic report and would like assistance with my Python development environment setup.

SYSTEM SUMMARY:
${summaryData.summary}

FAILED DIAGNOSTICS:
${summaryData.failures}

SYSTEM INFO:
- Report generated: ${new Date().toLocaleString()}
- Browser: ${navigator.userAgent}

Please note: I can provide the detailed diagnostic report file if needed. Use the "Download Report" button to save the complete report.

Please let me know how to resolve any issues found.

Best regards,
[Your Name]
[Your Student ID / Email]

---
This email was generated automatically by the DTU Python Diagnostics Report.`;

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

function generateEmailSummary() {
    let passed = 0, failed = 0, timeout = 0;
    const failures = [];
    
    for (const [key, data] of Object.entries(diagnosticData)) {
        if (data.status === 'PASS') {
            passed++;
        } else if (data.status === 'TIMEOUT') {
            timeout++;
            failures.push(`- ${data.name} (${data.category}) - TIMEOUT`);
        } else {
            failed++;
            failures.push(`- ${data.name} (${data.category}) - FAILED`);
        }
    }
    
    const summary = `Total Diagnostics: ${passed + failed + timeout}
Passed: ${passed}
Failed: ${failed}
Timeout: ${timeout}`;
    
    return {
        summary,
        failures: failures.length > 0 ? '\n' + failures.join('\n') : ''
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