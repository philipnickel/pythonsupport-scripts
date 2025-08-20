#!/bin/bash
# DTU Python Diagnostics Report Generator
# Auto-discovers and organizes diagnostic components by directory structure

set -euo pipefail

# Create secure temporary directory for logs
TEMP_DIR=$(mktemp -d -t "dtu_diagnostics")
trap "rm -rf '$TEMP_DIR'" EXIT INT TERM

# Output locations
REPORT_FILE="${1:-$HOME/Desktop/DTU_Python_Diagnostics_$(date +%Y%m%d_%H%M%S).html}"
LOG_DIR="$TEMP_DIR/logs"
mkdir -p "$LOG_DIR"

# Color codes for terminal output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🔍 DTU Python Diagnostics Report Generator"
echo "Temporary directory: $TEMP_DIR"
echo "Report will be saved to: $REPORT_FILE"
echo ""

# Function to extract metadata from diagnostic script
extract_metadata() {
    local script_path="$1"
    local field="$2"
    
    if [[ -f "$script_path" ]]; then
        grep "^# @$field:" "$script_path" 2>/dev/null | head -1 | cut -d':' -f2- | sed 's/^ *//'
    fi
}

# Function to auto-discover diagnostic components
discover_components() {
    local components_dir="$(dirname "$0")/Components"
    
    echo -e "${BLUE}Discovering diagnostic components...${NC}" >&2
    
    # Create temporary file to store categories
    local temp_categories="$TEMP_DIR/categories"
    > "$temp_categories"
    
    # Find all diagnostic scripts organized by directory
    while IFS= read -r -d '' script_path; do
        if [[ -f "$script_path" && "$script_path" == *.sh ]]; then
            # Extract category from directory structure
            local rel_path=$(python3 -c "import os.path; print(os.path.relpath('$script_path', '$components_dir'))" 2>/dev/null || basename "$script_path")
            local category=$(dirname "$rel_path")
            local script_name=$(basename "$script_path")
            
            # Skip if not in a subdirectory
            if [[ "$category" == "." ]]; then
                continue
            fi
            
            # Extract name from metadata or use filename
            local display_name=$(extract_metadata "$script_path" "name")
            if [[ -z "$display_name" ]]; then
                display_name=$(basename "$script_name" .sh | tr '_' ' ' | sed 's/\b\w/\U&/g')
            fi
            
            echo "  Found: $category/$script_name → $display_name" >&2
            echo "$category:$script_name:$display_name" >> "$temp_categories"
        fi
    done < <(find "$components_dir" -name "*.sh" -type f -print0 2>/dev/null)
    
    # Output discovered components in array format for later use
    echo "DISCOVERED_CATEGORIES=("
    while IFS=':' read -r category script_name display_name; do
        echo "  \"$category:$script_name:$display_name\""
    done < "$temp_categories" | sort
    echo ")"
}

# Run diagnostic component and capture result
run_diagnostic() {
    local category="$1"
    local script_name="$2"
    local display_name="$3"
    local script_path="$(dirname "$0")/Components/$category/$script_name"
    local log_file="$LOG_DIR/${category}_${script_name%.sh}.log"
    local exit_code=0
    
    echo -n "Running $category → $display_name... "
    
    if [[ ! -f "$script_path" ]]; then
        echo -e "${RED}✗ Script not found${NC}"
        echo "ERROR: Script not found: $script_path" > "$log_file"
        return 2
    fi
    
    # Run diagnostic and capture output
    if bash "$script_path" > "$log_file" 2>&1; then
        echo -e "${GREEN}✓ Passed${NC}"
        exit_code=0
    else
        exit_code=$?
        echo -e "${RED}✗ Failed (exit code: $exit_code)${NC}"
    fi
    
    return $exit_code
}

# Auto-discover components
echo "═══════════════════════════════════════"
discover_components > "$TEMP_DIR/components.sh"
source "$TEMP_DIR/components.sh"
echo "═══════════════════════════════════════"
echo ""

# Track overall results
TOTAL_PASS=0
TOTAL_FAIL=0
JSON_DATA=""
current_category=""

# Run all discovered diagnostic components
echo "Running diagnostic checks..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for category_data in "${DISCOVERED_CATEGORIES[@]}"; do
    IFS=':' read -r category script_name display_name <<< "$category_data"
    
    # Check if this is a new category
    if [[ "$category" != "$current_category" ]]; then
        current_category="$category"
        echo -e "\n${BLUE}📁 Category: $category${NC}"
        echo "────────────────────────"
    fi
    
    STATUS="FAIL"
    if run_diagnostic "$category" "$script_name" "$display_name"; then
        STATUS="PASS"
        ((TOTAL_PASS++))
    else
        ((TOTAL_FAIL++))
    fi
    
    # Get log content and base64 encode it
    log_file="$LOG_DIR/${category}_${script_name%.sh}.log"
    LOG_DATA=""
    if [[ -f "$log_file" ]]; then
        LOG_DATA=$(base64 < "$log_file" 2>/dev/null | tr -d '\n' || echo "")
    fi
    
    # Build JSON data
    if [[ -n "$JSON_DATA" ]]; then
        JSON_DATA="${JSON_DATA},"
    fi
    JSON_DATA="${JSON_DATA}
        '${category}_${script_name}': {
            category: '${category}',
            name: '${display_name}',
            status: '${STATUS}',
            log: '${LOG_DATA}'
        }"
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Generate HTML report with organized categories
echo "Generating HTML report with navigation..."

cat > "$REPORT_FILE" << 'HTML_TEMPLATE'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DTU Python Diagnostics Report</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
            display: grid;
            grid-template-columns: 250px 1fr;
            min-height: 80vh;
        }
        
        .sidebar {
            background: #f8f9fa;
            border-right: 1px solid #dee2e6;
            padding: 20px;
            overflow-y: auto;
        }
        
        .main-content {
            display: flex;
            flex-direction: column;
        }
        
        header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .timestamp {
            opacity: 0.9;
            font-size: 0.9em;
        }
        
        .summary {
            display: flex;
            justify-content: center;
            gap: 40px;
            padding: 30px;
            background: #f8f9fa;
            border-bottom: 1px solid #dee2e6;
        }
        
        .summary-item {
            text-align: center;
        }
        
        .summary-number {
            font-size: 3em;
            font-weight: bold;
        }
        
        .summary-label {
            color: #6c757d;
            text-transform: uppercase;
            font-size: 0.8em;
            letter-spacing: 1px;
        }
        
        .passed { color: #28a745; }
        .failed { color: #dc3545; }
        .total { color: #007bff; }
        
        .nav-category {
            margin-bottom: 20px;
        }
        
        .nav-category h3 {
            font-size: 1em;
            color: #495057;
            margin-bottom: 8px;
            padding: 8px 12px;
            background: #e9ecef;
            border-radius: 5px;
            cursor: pointer;
        }
        
        .nav-items {
            margin-left: 15px;
        }
        
        .nav-item {
            padding: 5px 10px;
            margin: 2px 0;
            border-radius: 3px;
            cursor: pointer;
            font-size: 0.9em;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .nav-item:hover {
            background: #e9ecef;
        }
        
        .nav-item.active {
            background: #007bff;
            color: white;
        }
        
        .nav-status {
            width: 12px;
            height: 12px;
            border-radius: 50%;
        }
        
        .nav-status.pass { background: #28a745; }
        .nav-status.fail { background: #dc3545; }
        
        .diagnostics {
            padding: 30px;
            flex: 1;
            overflow-y: auto;
        }
        
        .category-section {
            margin-bottom: 40px;
            display: none;
        }
        
        .category-section.active {
            display: block;
        }
        
        .category-header {
            font-size: 1.8em;
            color: #495057;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #007bff;
        }
        
        .diagnostic-item {
            background: white;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            margin-bottom: 20px;
            overflow: hidden;
            transition: box-shadow 0.3s;
        }
        
        .diagnostic-item:hover {
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        
        .diagnostic-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 20px;
            cursor: pointer;
            user-select: none;
            background: #f8f9fa;
        }
        
        .diagnostic-header:hover {
            background: #e9ecef;
        }
        
        .diagnostic-name {
            font-weight: 600;
            font-size: 1.1em;
        }
        
        .diagnostic-status {
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .status-pass {
            background: #d4edda;
            color: #155724;
        }
        
        .status-fail {
            background: #f8d7da;
            color: #721c24;
        }
        
        .diagnostic-log {
            padding: 20px;
            background: #1e1e1e;
            color: #d4d4d4;
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
            font-size: 0.9em;
            white-space: pre-wrap;
            word-wrap: break-word;
            max-height: 500px;
            overflow-y: auto;
            display: none;
            border-top: 3px solid #007bff;
        }
        
        .diagnostic-log.active {
            display: block;
        }
        
        .expand-icon {
            transition: transform 0.3s;
            margin-left: 10px;
        }
        
        .expanded .expand-icon {
            transform: rotate(180deg);
        }
        
        footer {
            text-align: center;
            padding: 20px;
            background: #f8f9fa;
            color: #6c757d;
            font-size: 0.9em;
        }
        
        .notice {
            background: #fff3cd;
            border: 1px solid #ffc107;
            border-radius: 5px;
            padding: 15px;
            margin: 20px 30px;
            color: #856404;
        }
        
        .notice-title {
            font-weight: bold;
            margin-bottom: 5px;
        }

        /* Scrollbar styling */
        .diagnostic-log::-webkit-scrollbar,
        .sidebar::-webkit-scrollbar,
        .diagnostics::-webkit-scrollbar {
            width: 8px;
        }
        
        .diagnostic-log::-webkit-scrollbar-track,
        .sidebar::-webkit-scrollbar-track,
        .diagnostics::-webkit-scrollbar-track {
            background: #f1f1f1;
        }
        
        .diagnostic-log::-webkit-scrollbar-thumb,
        .sidebar::-webkit-scrollbar-thumb,
        .diagnostics::-webkit-scrollbar-thumb {
            background: #888;
            border-radius: 4px;
        }
        
        .diagnostic-log::-webkit-scrollbar-thumb:hover,
        .sidebar::-webkit-scrollbar-thumb:hover,
        .diagnostics::-webkit-scrollbar-thumb:hover {
            background: #555;
        }
        
        /* Mobile responsive */
        @media (max-width: 768px) {
            .container {
                grid-template-columns: 1fr;
                margin: 10px;
            }
            
            .sidebar {
                order: 2;
                border-right: none;
                border-top: 1px solid #dee2e6;
                max-height: 200px;
            }
            
            .main-content {
                order: 1;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="sidebar">
            <h2 style="margin-bottom: 20px; color: #495057;">Navigation</h2>
            <div id="navigation">
                <!-- Navigation will be generated here -->
            </div>
        </div>
        
        <div class="main-content">
            <header>
                <h1>🔍 DTU Python Diagnostics Report</h1>
                <div class="timestamp">Generated on: <span id="timestamp"></span></div>
            </header>
            
            <div class="summary">
                <div class="summary-item">
                    <div class="summary-number passed" id="passed-count">0</div>
                    <div class="summary-label">Passed</div>
                </div>
                <div class="summary-item">
                    <div class="summary-number failed" id="failed-count">0</div>
                    <div class="summary-label">Failed</div>
                </div>
                <div class="summary-item">
                    <div class="summary-number total" id="total-count">0</div>
                    <div class="summary-label">Total Checks</div>
                </div>
            </div>
            
            <div class="notice">
                <div class="notice-title">ℹ️ Auto-Generated Report</div>
                This report was automatically generated by discovering diagnostic components.
                All data is embedded and works offline.
            </div>
            
            <div class="diagnostics" id="diagnostics-container">
                <!-- Diagnostic categories and items will be inserted here -->
            </div>
            
            <footer>
                <p>DTU Python Support | Technical University of Denmark</p>
                <p>Auto-discovered diagnostic components with organized navigation.</p>
            </footer>
        </div>
    </div>
    
    <script>
        // Embedded diagnostic data (base64 encoded logs)
        const diagnosticData = {
HTML_TEMPLATE

# Insert the JSON data
echo "$JSON_DATA" >> "$REPORT_FILE"

# Complete the HTML
cat >> "$REPORT_FILE" << 'HTML_FOOTER'
        };
        
        // Initialize report
        document.addEventListener('DOMContentLoaded', function() {
            // Set timestamp
            document.getElementById('timestamp').textContent = new Date().toLocaleString();
            
            // Organize data by categories
            const categories = {};
            let passed = 0;
            let failed = 0;
            
            for (const [key, data] of Object.entries(diagnosticData)) {
                if (data.status === 'PASS') passed++;
                else failed++;
                
                if (!categories[data.category]) {
                    categories[data.category] = [];
                }
                categories[data.category].push({key, ...data});
            }
            
            // Generate navigation
            generateNavigation(categories);
            
            // Generate diagnostic sections
            generateDiagnosticSections(categories);
            
            // Show first category by default
            const firstCategory = Object.keys(categories)[0];
            if (firstCategory) {
                showCategory(firstCategory);
            }
            
            // Update summary
            document.getElementById('passed-count').textContent = passed;
            document.getElementById('failed-count').textContent = failed;
            document.getElementById('total-count').textContent = passed + failed;
        });
        
        function generateNavigation(categories) {
            const nav = document.getElementById('navigation');
            
            for (const [categoryName, items] of Object.entries(categories)) {
                const categoryDiv = document.createElement('div');
                categoryDiv.className = 'nav-category';
                
                const categoryHeader = document.createElement('h3');
                categoryHeader.textContent = `📁 ${categoryName}`;
                categoryHeader.onclick = () => showCategory(categoryName);
                
                const itemsDiv = document.createElement('div');
                itemsDiv.className = 'nav-items';
                
                items.forEach(item => {
                    const navItem = document.createElement('div');
                    navItem.className = 'nav-item';
                    navItem.onclick = () => {
                        showCategory(categoryName);
                        setTimeout(() => scrollToItem(item.key), 100);
                    };
                    
                    const status = document.createElement('div');
                    status.className = `nav-status ${item.status.toLowerCase()}`;
                    
                    const name = document.createElement('span');
                    name.textContent = item.name;
                    
                    navItem.appendChild(status);
                    navItem.appendChild(name);
                    itemsDiv.appendChild(navItem);
                });
                
                categoryDiv.appendChild(categoryHeader);
                categoryDiv.appendChild(itemsDiv);
                nav.appendChild(categoryDiv);
            }
        }
        
        function generateDiagnosticSections(categories) {
            const container = document.getElementById('diagnostics-container');
            
            for (const [categoryName, items] of Object.entries(categories)) {
                const section = document.createElement('div');
                section.className = 'category-section';
                section.id = `category-${categoryName}`;
                
                const header = document.createElement('div');
                header.className = 'category-header';
                header.textContent = `📁 ${categoryName}`;
                section.appendChild(header);
                
                items.forEach(item => {
                    // Decode log data
                    let logContent = '';
                    try {
                        logContent = item.log ? atob(item.log) : 'No log data available';
                    } catch (e) {
                        logContent = 'Error decoding log data';
                    }
                    
                    // Create diagnostic item
                    const itemDiv = document.createElement('div');
                    itemDiv.className = 'diagnostic-item';
                    itemDiv.id = `item-${item.key}`;
                    itemDiv.innerHTML = `
                        <div class="diagnostic-header" onclick="toggleLog(this)">
                            <span class="diagnostic-name">${item.name}</span>
                            <div>
                                <span class="diagnostic-status status-${item.status.toLowerCase()}">${item.status}</span>
                                <span class="expand-icon">▼</span>
                            </div>
                        </div>
                        <div class="diagnostic-log">${escapeHtml(logContent)}</div>
                    `;
                    section.appendChild(itemDiv);
                });
                
                container.appendChild(section);
            }
        }
        
        function showCategory(categoryName) {
            // Hide all sections
            document.querySelectorAll('.category-section').forEach(section => {
                section.classList.remove('active');
            });
            
            // Show selected section
            const section = document.getElementById(`category-${categoryName}`);
            if (section) {
                section.classList.add('active');
            }
            
            // Update navigation
            document.querySelectorAll('.nav-item').forEach(item => {
                item.classList.remove('active');
            });
        }
        
        function scrollToItem(itemKey) {
            const item = document.getElementById(`item-${itemKey}`);
            if (item) {
                item.scrollIntoView({ behavior: 'smooth', block: 'start' });
                item.style.backgroundColor = '#fff3cd';
                setTimeout(() => {
                    item.style.backgroundColor = '';
                }, 2000);
            }
        }
        
        function toggleLog(header) {
            const item = header.parentElement;
            const log = item.querySelector('.diagnostic-log');
            
            item.classList.toggle('expanded');
            log.classList.toggle('active');
        }
        
        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
    </script>
</body>
</html>
HTML_FOOTER

echo "✅ Report generated successfully!"
echo ""
echo "📊 Summary:"
echo "   Passed: $TOTAL_PASS"
echo "   Failed: $TOTAL_FAIL"
echo "   Total:  $((TOTAL_PASS + TOTAL_FAIL))"
echo ""
echo "📄 Report saved to: $REPORT_FILE"
echo ""

# Open the report in default browser
if command -v open >/dev/null 2>&1; then
    echo "Opening report in browser..."
    open "$REPORT_FILE"
fi

# Temp directory will be automatically cleaned up by trap on exit
echo "✨ Temporary files will be automatically cleaned up"

exit 0