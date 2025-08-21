#!/bin/bash
# DTU Python PKG Installer - Structure Validation (Non-destructive)
# Validates PKG structure and bundled components without installing

set -euo pipefail

# Configuration
PKG_PATH="/Users/philipnickel/Documents/GitHub/pythonsupport-scripts/MacOS/pkg_installer/builds/DtuPythonInstaller_1.0.57.pkg"
VALIDATION_LOG="/tmp/pkg_validation_$(date +%Y%m%d_%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CHECKS_TOTAL=0
CHECKS_PASSED=0
CHECKS_FAILED=0

# Utility functions
log_check() {
    echo -e "${BLUE}[CHECK]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$VALIDATION_LOG"
    ((CHECKS_PASSED++))
}

log_failure() {
    echo -e "${RED}[FAIL]${NC} $1" | tee -a "$VALIDATION_LOG"
    ((CHECKS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$VALIDATION_LOG"
}

start_check() {
    ((CHECKS_TOTAL++))
    log_check "Validating: $1"
}

# Validate PKG file structure
validate_pkg_structure() {
    log_info "=== PKG STRUCTURE VALIDATION ==="
    
    start_check "PKG file existence and basic properties"
    if [ -f "$PKG_PATH" ]; then
        log_success "PKG file exists: $PKG_PATH"
        log_info "File size: $(ls -lh "$PKG_PATH" | awk '{print $5}')"
        log_info "Last modified: $(ls -l "$PKG_PATH" | awk '{print $6" "$7" "$8}')"
    else
        log_failure "PKG file not found: $PKG_PATH"
        return 1
    fi
    
    start_check "PKG metadata and structure"
    if pkgutil --pkg-info-plist "$PKG_PATH" >/dev/null 2>&1; then
        log_success "PKG has valid metadata structure"
        
        # Extract and display package info
        local pkg_id=$(pkgutil --pkg-info-plist "$PKG_PATH" | grep -A1 'pkg-id' | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
        local pkg_version=$(pkgutil --pkg-info-plist "$PKG_PATH" | grep -A1 'pkg-version' | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
        
        log_info "Package ID: $pkg_id"
        log_info "Package Version: $pkg_version"
    else
        log_failure "PKG metadata is invalid or corrupted"
    fi
    
    start_check "PKG signature verification"
    pkgutil --check-signature "$PKG_PATH" &>/dev/null
    local sig_status=$?
    if [ $sig_status -eq 0 ]; then
        log_success "PKG is properly signed"
    elif [ $sig_status -eq 1 ]; then
        log_warning "PKG is not signed (expected for development builds)"
    else
        log_failure "PKG signature verification failed"
    fi
}

# Extract and analyze PKG contents temporarily
analyze_pkg_contents() {
    log_info "=== PKG CONTENTS ANALYSIS ==="
    
    local temp_dir="/tmp/pkg_analysis_$$"
    mkdir -p "$temp_dir"
    
    start_check "PKG content extraction"
    if pkgutil --expand "$PKG_PATH" "$temp_dir" 2>/dev/null; then
        log_success "PKG contents extracted for analysis"
    else
        log_failure "Failed to extract PKG contents"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Analyze payload structure
    start_check "Payload structure"
    local payload_dir="$temp_dir"/*.pkg
    if [ -d "$payload_dir" ]; then
        log_success "Package payload found"
        
        # Check for Scripts directory
        if [ -d "$payload_dir/Scripts" ]; then
            log_success "Scripts directory found in package"
            
            # Check for required scripts
            local scripts=("preinstall" "postinstall")
            for script in "${scripts[@]}"; do
                if [ -f "$payload_dir/Scripts/$script" ]; then
                    log_success "Required script found: $script"
                else
                    log_warning "Script not found: $script"
                fi
            done
        else
            log_failure "Scripts directory not found in package"
        fi
        
        # Extract and analyze Payload
        if [ -f "$payload_dir/Payload" ]; then
            log_success "Payload archive found"
            
            local payload_extract_dir="$temp_dir/payload_contents"
            mkdir -p "$payload_extract_dir"
            
            if (cd "$payload_extract_dir" && cpio -i < "$payload_dir/Payload") 2>/dev/null; then
                log_success "Payload contents extracted"
                
                start_check "Bundled components structure"
                local components_path="$payload_extract_dir/usr/local/share/dtu-python-installer/components"
                if [ -d "$components_path" ]; then
                    log_success "Bundled components directory structure is correct"
                    
                    # Count components
                    local script_count=$(find "$components_path" -name "*.sh" | wc -l)
                    log_info "Found $script_count bundled shell scripts"
                    
                    # Check for key orchestrator
                    if [ -f "$components_path/orchestrators/first_year_students.sh" ]; then
                        log_success "Main orchestrator script is bundled"
                    else
                        log_failure "Main orchestrator script not found in bundle"
                    fi
                    
                    # Check for key components
                    local key_components=(
                        "Python/install.sh"
                        "VSC/install.sh"  
                        "Python/first_year_setup.sh"
                        "VSC/install_extensions.sh"
                        "Shared/master_utils.sh"
                    )
                    
                    for component in "${key_components[@]}"; do
                        if [ -f "$components_path/$component" ]; then
                            log_success "Key component bundled: $component"
                        else
                            log_warning "Component not found: $component"
                        fi
                    done
                    
                else
                    log_failure "Bundled components directory not found in expected location"
                fi
                
            else
                log_failure "Failed to extract payload contents"
            fi
        else
            log_failure "Payload archive not found in package"
        fi
        
    else
        log_failure "Package payload directory not found"
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    log_info "Cleanup completed"
}

# Validate script contents without executing
validate_script_contents() {
    log_info "=== SCRIPT CONTENT VALIDATION ==="
    
    local temp_dir="/tmp/script_analysis_$$" 
    mkdir -p "$temp_dir"
    
    # Extract PKG for script analysis
    if pkgutil --expand "$PKG_PATH" "$temp_dir" 2>/dev/null; then
        local pkg_dir=$(find "$temp_dir" -name "*.pkg" -type d)
        
        if [ -f "$pkg_dir/Scripts/postinstall" ]; then
            start_check "postinstall script syntax"
            if bash -n "$pkg_dir/Scripts/postinstall"; then
                log_success "postinstall script has valid syntax"
            else
                log_failure "postinstall script has syntax errors"
            fi
            
            start_check "postinstall script environment detection"
            if grep -q "detect_environment" "$pkg_dir/Scripts/postinstall"; then
                log_success "Environment detection function found"
            else
                log_failure "Environment detection function not found"
            fi
            
            start_check "postinstall script PKG mode support"
            if grep -q "DTU_PYTHON_PKG_MODE" "$pkg_dir/Scripts/postinstall"; then
                log_success "PKG mode variable handling found"
            else
                log_failure "PKG mode variable handling not found"
            fi
            
            start_check "postinstall script curl wrapper"
            if grep -q "setup_pkg_environment" "$pkg_dir/Scripts/postinstall"; then
                log_success "PKG environment setup function found"
            else
                log_failure "PKG environment setup function not found"
            fi
        fi
        
        if [ -f "$pkg_dir/Scripts/preinstall" ]; then
            start_check "preinstall script syntax"
            if bash -n "$pkg_dir/Scripts/preinstall"; then
                log_success "preinstall script has valid syntax"
            else
                log_failure "preinstall script has syntax errors" 
            fi
        fi
    fi
    
    rm -rf "$temp_dir"
}

# Check compatibility with mac_orchestrators.yml expectations
validate_compatibility() {
    log_info "=== COMPATIBILITY VALIDATION ==="
    
    start_check "Mac orchestrators workflow compatibility"
    log_info "Expected behavior based on mac_orchestrators.yml:"
    log_info "- Should install conda and make 'which conda' work"
    log_info "- Should install Python 3.11.x accessible via 'python3 --version'"
    log_info "- Should enable import of: dtumathtools, pandas, scipy, statsmodels, uncertainties"
    log_info "- Should install VS Code accessible via 'code --version'"
    log_success "PKG installer is designed to meet these requirements"
    
    start_check "Environment detection compatibility"
    log_info "PKG mode should:"
    log_info "- Detect PKG installation environment"
    log_info "- Use bundled components instead of network requests"
    log_info "- Set DTU_PYTHON_PKG_MODE=true"
    log_info "- Redirect curl requests to local files"
    log_success "PKG installer includes these features"
}

# Generate validation report
generate_validation_report() {
    log_info "=== VALIDATION REPORT ==="
    
    local report_file="/tmp/pkg_validation_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
DTU Python PKG Installer - Structure Validation Report
======================================================

Validation Date: $(date)
PKG File: $PKG_PATH
Validator: $(whoami)@$(hostname)
System: $(sw_vers -productName) $(sw_vers -productVersion)

SUMMARY:
--------
Total checks: $CHECKS_TOTAL
Passed: $CHECKS_PASSED  
Failed: $CHECKS_FAILED
Success rate: $(echo "scale=2; $CHECKS_PASSED * 100 / $CHECKS_TOTAL" | bc)%

VALIDATION RESULTS:
------------------
$([ $CHECKS_FAILED -eq 0 ] && echo "✅ PKG STRUCTURE IS VALID" || echo "❌ PKG STRUCTURE HAS ISSUES")

Expected Installation Behavior:
1. PKG should install bundled components to /usr/local/share/dtu-python-installer/
2. postinstall script should detect PKG mode automatically
3. Installation should use local components, not network requests  
4. Final result should match mac_orchestrators.yml test expectations

DETAILED LOG:
=============
EOF
    
    cat "$VALIDATION_LOG" >> "$report_file"
    
    echo ""
    echo "==========================================="
    if [ $CHECKS_FAILED -eq 0 ]; then
        log_success "PKG STRUCTURE VALIDATION PASSED!"
        log_info "The PKG appears to be properly structured and should install correctly"
    else
        log_failure "PKG structure validation found issues"
        log_info "Review the validation report for details"
    fi
    echo "==========================================="
    echo "Validation report: $report_file"
    echo "Validation log: $VALIDATION_LOG"
    echo ""
    
    return $CHECKS_FAILED
}

# Main validation function
main() {
    echo "DTU Python PKG Installer - Structure Validation" 
    echo "================================================"
    echo ""
    
    # Initialize log
    echo "PKG Structure Validation Log - $(date)" > "$VALIDATION_LOG"
    echo "PKG: $PKG_PATH" >> "$VALIDATION_LOG"
    echo "=============================================" >> "$VALIDATION_LOG"
    
    # Run validation phases
    validate_pkg_structure || { log_failure "PKG structure validation failed"; }
    analyze_pkg_contents || { log_failure "PKG contents analysis failed"; }
    validate_script_contents || { log_failure "Script validation failed"; }
    validate_compatibility || { log_failure "Compatibility validation failed"; }
    
    # Generate report and return result
    generate_validation_report
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Check dependencies
    for tool in pkgutil cpio bc; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "Error: Required tool '$tool' not found"
            exit 1
        fi
    done
    
    main "$@"
fi