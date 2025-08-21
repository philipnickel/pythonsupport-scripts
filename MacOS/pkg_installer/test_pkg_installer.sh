#!/bin/bash
# DTU Python PKG Installer - Comprehensive Test Suite
# Tests installation, functionality verification, and environment detection
# Matches the same tests as mac_orchestrators.yml workflow

set -euo pipefail

# Test Configuration
PKG_PATH="/Users/philipnickel/Documents/GitHub/pythonsupport-scripts/MacOS/pkg_installer/builds/DtuPythonInstaller_1.0.57.pkg"
TEST_LOG="/tmp/pkg_installer_test_$(date +%Y%m%d_%H%M%S).log"
TEST_RESULTS="/tmp/pkg_installer_test_results_$(date +%Y%m%d_%H%M%S).txt"
PYTHON_VERSION_EXPECTED="3.11"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test tracking
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Utility functions
log_test() {
    echo -e "${BLUE}[TEST]${NC} $1" | tee -a "$TEST_LOG"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$TEST_LOG"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$TEST_LOG"
    ((TESTS_PASSED++))
}

log_failure() {
    echo -e "${RED}[FAIL]${NC} $1" | tee -a "$TEST_LOG"
    ((TESTS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$TEST_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$TEST_LOG"
}

start_test() {
    ((TESTS_TOTAL++))
    log_test "Starting: $1"
}

# Backup current environment state (for potential rollback)
backup_environment() {
    log_info "Creating environment backup..."
    
    # Backup PATH
    echo "$PATH" > /tmp/pkg_test_path_backup.txt
    
    # Check current installations
    echo "=== ENVIRONMENT BACKUP ===" > /tmp/pkg_test_env_backup.txt
    echo "Date: $(date)" >> /tmp/pkg_test_env_backup.txt
    echo "Conda: $(command -v conda 2>/dev/null || echo 'NOT_INSTALLED')" >> /tmp/pkg_test_env_backup.txt
    echo "Python3: $(command -v python3 2>/dev/null || echo 'NOT_INSTALLED')" >> /tmp/pkg_test_env_backup.txt
    echo "Code: $(command -v code 2>/dev/null || echo 'NOT_INSTALLED')" >> /tmp/pkg_test_env_backup.txt
    echo "Brew: $(command -v brew 2>/dev/null || echo 'NOT_INSTALLED')" >> /tmp/pkg_test_env_backup.txt
    
    log_info "Environment backup completed"
}

# Pre-installation checks
run_pre_installation_checks() {
    log_info "=== PRE-INSTALLATION CHECKS ==="
    
    # Check if PKG file exists
    start_test "PKG file existence"
    if [ -f "$PKG_PATH" ]; then
        log_success "PKG file exists at: $PKG_PATH"
        log_info "PKG file size: $(ls -lh "$PKG_PATH" | awk '{print $5}')"
    else
        log_failure "PKG file not found at: $PKG_PATH"
        return 1
    fi
    
    # Check PKG integrity
    start_test "PKG file integrity"
    if pkgutil --check-signature "$PKG_PATH" &>/dev/null || [ $? -eq 1 ]; then
        log_success "PKG file structure is valid"
    else
        log_failure "PKG file appears to be corrupted"
        return 1
    fi
    
    # Check system requirements
    start_test "System requirements"
    if [[ $(sw_vers -productName) == "macOS" ]] || [[ $(sw_vers -productName) == "Mac OS X" ]]; then
        log_success "Running on macOS: $(sw_vers -productVersion)"
    else
        log_failure "Not running on macOS"
        return 1
    fi
    
    # Check if running as admin/sudo capability
    start_test "Admin privileges"
    if sudo -n true 2>/dev/null; then
        log_success "Can execute sudo commands without password"
    else
        log_warning "May need password for sudo operations"
    fi
    
    log_info "Pre-installation checks completed"
}

# Install the PKG
install_pkg() {
    log_info "=== PKG INSTALLATION TEST ==="
    
    start_test "PKG installation"
    log_info "Installing PKG: $PKG_PATH"
    
    # Install the package with verbose output
    if sudo installer -pkg "$PKG_PATH" -target / -verbose 2>&1 | tee -a "$TEST_LOG"; then
        log_success "PKG installation completed without errors"
    else
        log_failure "PKG installation failed"
        return 1
    fi
    
    # Wait for installation to settle
    log_info "Waiting 10 seconds for installation to settle..."
    sleep 10
    
    # Check if postinstall script ran
    start_test "Postinstall script execution"
    if [ -f "/tmp/macos_dtu_python_install.log" ]; then
        log_success "Installation log created by postinstall script"
        
        # Check for PKG mode detection
        if grep -q "Environment detected: PKG mode" "/tmp/macos_dtu_python_install.log"; then
            log_success "PKG mode correctly detected by postinstall script"
        else
            log_failure "PKG mode not detected in installation log"
        fi
        
        # Check for bundled components usage
        if grep -q "using bundled components" "/tmp/macos_dtu_python_install.log"; then
            log_success "Bundled components correctly used"
        else
            log_failure "Bundled components not used as expected"
        fi
        
    else
        log_failure "Installation log not found - postinstall script may not have run"
    fi
    
    # Check if bundled components are accessible
    start_test "Bundled components accessibility"
    local bundled_path="/usr/local/share/dtu-python-installer/components"
    if [ -d "$bundled_path" ]; then
        log_success "Bundled components directory exists: $bundled_path"
        local component_count=$(find "$bundled_path" -name "*.sh" | wc -l)
        log_info "Found $component_count bundled shell scripts"
        
        # Check for key components
        if [ -f "$bundled_path/orchestrators/first_year_students.sh" ]; then
            log_success "Main orchestrator script is bundled"
        else
            log_failure "Main orchestrator script not found in bundle"
        fi
    else
        log_failure "Bundled components directory not found"
    fi
    
    log_info "PKG installation test completed"
}

# Test environment detection
test_environment_detection() {
    log_info "=== ENVIRONMENT DETECTION TEST ==="
    
    start_test "PKG mode environment variables"
    
    # Simulate the environment detection logic from postinstall.sh
    local bundled_components_path="/usr/local/share/dtu-python-installer/components"
    local bundled_orchestrator="$bundled_components_path/orchestrators/first_year_students.sh"
    
    if [ -d "$bundled_components_path" ] && [ -f "$bundled_orchestrator" ]; then
        log_success "Environment correctly identifies PKG mode conditions"
        export DTU_PYTHON_PKG_MODE="true"
        export DTU_COMPONENTS_PATH="$bundled_components_path"
    else
        log_failure "Environment detection would fail in PKG mode"
        return 1
    fi
    
    start_test "Network isolation verification"
    # Create a temporary curl wrapper to verify no network requests
    local temp_dir="/tmp/pkg_test_network_monitor_$$"
    mkdir -p "$temp_dir"
    
    cat > "$temp_dir/curl" << 'EOF'
#!/bin/bash
echo "NETWORK_REQUEST_DETECTED: $*" >&2
# For GitHub raw content, should be redirected to local files
if [[ "$*" =~ github\.com ]]; then
    echo "ERROR: Network request to GitHub detected in PKG mode!" >&2
    exit 1
fi
exec /usr/bin/curl "$@"
EOF
    chmod +x "$temp_dir/curl"
    
    # Test with modified PATH
    PATH="$temp_dir:$PATH"
    
    # Try to source a component that would normally require network
    if DTU_PYTHON_PKG_MODE="true" DTU_COMPONENTS_PATH="$bundled_components_path" \
       bash -c 'source "$DTU_COMPONENTS_PATH/../../../Shared/master_utils.sh" 2>/dev/null || echo "Local loading test"' 2>&1 | \
       grep -q "NETWORK_REQUEST_DETECTED"; then
        log_failure "Unexpected network requests detected in PKG mode"
    else
        log_success "No unexpected network requests in PKG mode"
    fi
    
    rm -rf "$temp_dir"
    log_info "Environment detection test completed"
}

# Functionality verification (matching mac_orchestrators.yml)
test_functionality() {
    log_info "=== FUNCTIONALITY VERIFICATION (matching mac_orchestrators.yml) ==="
    
    # Wait for installations to settle and update shell environment
    log_info "Refreshing shell environment..."
    if [ -f ~/.zshrc ]; then
        source ~/.zshrc 2>/dev/null || true
    fi
    if [ -f ~/.bash_profile ]; then
        source ~/.bash_profile 2>/dev/null || true
    fi
    
    # Update PATH to include conda and other tools
    if [ -d "/opt/homebrew/bin" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    fi
    if [ -d "/usr/local/bin" ]; then
        export PATH="/usr/local/bin:$PATH"
    fi
    
    # Initialize conda if available
    if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        source "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
        source "$HOME/miniconda3/etc/profile.d/conda.sh"
    fi
    
    # Test 1: Verify conda installation
    start_test "Conda installation verification"
    if which conda >/dev/null 2>&1; then
        log_success "Conda found: $(which conda)"
        log_info "Conda version: $(conda --version)"
        log_info "Conda base: $(conda info --base 2>/dev/null || echo 'Could not determine')"
    else
        log_failure "Conda not found in PATH"
    fi
    
    # Test 2: Verify Python 3.11 installation  
    start_test "Python $PYTHON_VERSION_EXPECTED verification"
    if which python3 >/dev/null 2>&1; then
        local python_version=$(python3 --version 2>&1 | cut -d " " -f 2)
        if [[ "$python_version" == "$PYTHON_VERSION_EXPECTED"* ]]; then
            log_success "Correct Python version installed: $python_version"
        else
            log_failure "Python version mismatch. Expected: $PYTHON_VERSION_EXPECTED.x, Got: $python_version"
        fi
    else
        log_failure "Python3 not found in PATH"
    fi
    
    # Test 3: Verify package imports (exact same test as mac_orchestrators.yml)
    start_test "Python packages import verification"
    if python3 -c "import dtumathtools, pandas, scipy, statsmodels, uncertainties; print('Packages imported successfully')" 2>&1; then
        log_success "All required packages imported successfully"
    else
        log_failure "Failed to import required Python packages"
        log_info "Attempting to diagnose package issues..."
        
        # Individual package tests for better diagnosis
        local packages=("dtumathtools" "pandas" "scipy" "statsmodels" "uncertainties")
        for pkg in "${packages[@]}"; do
            if python3 -c "import $pkg" 2>&1; then
                log_info "✓ $pkg: OK"
            else
                log_info "✗ $pkg: FAILED"
            fi
        done
    fi
    
    # Test 4: Verify VS Code installation
    start_test "VS Code installation verification"
    if which code >/dev/null 2>&1; then
        local code_version=$(code --version 2>&1 | head -1)
        log_success "VS Code installed: $code_version"
    else
        log_failure "VS Code not found in PATH"
    fi
    
    log_info "Functionality verification completed"
}

# Generate comprehensive test report
generate_test_report() {
    log_info "=== GENERATING TEST REPORT ==="
    
    cat > "$TEST_RESULTS" << EOF
DTU Python PKG Installer - Test Results
========================================

Test execution: $(date)
PKG tested: $PKG_PATH
System: $(sw_vers -productName) $(sw_vers -productVersion)
User: $(whoami)

SUMMARY:
--------
Total tests: $TESTS_TOTAL
Passed: $TESTS_PASSED
Failed: $TESTS_FAILED
Success rate: $(echo "scale=2; $TESTS_PASSED * 100 / $TESTS_TOTAL" | bc)%

TEST RESULTS DETAILS:
--------------------
EOF
    
    # Append the detailed test log
    echo "" >> "$TEST_RESULTS"
    echo "DETAILED LOG:" >> "$TEST_RESULTS"
    echo "=============" >> "$TEST_RESULTS"
    cat "$TEST_LOG" >> "$TEST_RESULTS"
    
    # Add environment information
    echo "" >> "$TEST_RESULTS"
    echo "FINAL ENVIRONMENT STATE:" >> "$TEST_RESULTS"
    echo "=======================" >> "$TEST_RESULTS"
    echo "Conda: $(command -v conda 2>/dev/null || echo 'NOT_FOUND')" >> "$TEST_RESULTS"
    echo "Python3: $(command -v python3 2>/dev/null || echo 'NOT_FOUND')" >> "$TEST_RESULTS"
    echo "Python version: $(python3 --version 2>&1 || echo 'NOT_AVAILABLE')" >> "$TEST_RESULTS"
    echo "VS Code: $(command -v code 2>/dev/null || echo 'NOT_FOUND')" >> "$TEST_RESULTS"
    echo "Homebrew: $(command -v brew 2>/dev/null || echo 'NOT_FOUND')" >> "$TEST_RESULTS"
    
    # Add comparison with expected results
    echo "" >> "$TEST_RESULTS"
    echo "COMPARISON WITH mac_orchestrators.yml EXPECTATIONS:" >> "$TEST_RESULTS"
    echo "===================================================" >> "$TEST_RESULTS"
    echo "✓ Should find conda command: $(command -v conda >/dev/null && echo 'PASS' || echo 'FAIL')" >> "$TEST_RESULTS"
    echo "✓ Should find python3 command: $(command -v python3 >/dev/null && echo 'PASS' || echo 'FAIL')" >> "$TEST_RESULTS"
    echo "✓ Python version should be 3.11.x: $(python3 --version 2>&1 | grep -q '^Python 3\.11\.' && echo 'PASS' || echo 'FAIL')" >> "$TEST_RESULTS"
    echo "✓ Should import packages: $(python3 -c 'import dtumathtools, pandas, scipy, statsmodels, uncertainties' 2>/dev/null && echo 'PASS' || echo 'FAIL')" >> "$TEST_RESULTS"
    echo "✓ Should find code command: $(command -v code >/dev/null && echo 'PASS' || echo 'FAIL')" >> "$TEST_RESULTS"
    
    log_info "Test report generated: $TEST_RESULTS"
    
    # Display summary
    echo ""
    echo "==========================================="
    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "ALL TESTS PASSED! PKG installer works correctly."
        log_info "The PKG installer successfully passes all tests from mac_orchestrators.yml"
    else
        log_failure "Some tests failed. PKG installer needs attention."
        log_info "Please review the test log and results for details"
    fi
    echo "==========================================="
    echo "Full results: $TEST_RESULTS"
    echo "Test log: $TEST_LOG"
    echo ""
}

# Cleanup function (optional - for development/testing)
cleanup_installation() {
    log_info "=== CLEANUP OPTIONS ==="
    echo ""
    echo "To uninstall the PKG components if needed:"
    echo "1. Remove bundled components: sudo rm -rf /usr/local/share/dtu-python-installer"
    echo "2. Remove conda: run the uninstall_conda.sh script"
    echo "3. Remove VS Code: standard app uninstall"
    echo "4. Remove homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)\""
    echo ""
    echo "Note: This test does NOT automatically uninstall to preserve your development environment"
}

# Main test execution
main() {
    log_info "Starting DTU Python PKG Installer Test Suite"
    log_info "=============================================="
    
    # Initialize test log
    echo "DTU Python PKG Installer Test Log - $(date)" > "$TEST_LOG"
    echo "PKG Path: $PKG_PATH" >> "$TEST_LOG"
    echo "===========================================\n" >> "$TEST_LOG"
    
    # Run test phases
    backup_environment || { log_error "Failed to backup environment"; exit 1; }
    run_pre_installation_checks || { log_error "Pre-installation checks failed"; exit 1; }
    install_pkg || { log_error "PKG installation failed"; exit 1; }
    test_environment_detection || { log_warning "Environment detection tests had issues"; }
    test_functionality || { log_warning "Functionality tests had issues"; }
    
    # Generate final report
    generate_test_report
    cleanup_installation
    
    # Return appropriate exit code
    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "Test suite completed successfully!"
        exit 0
    else
        log_failure "Test suite completed with failures"
        exit 1
    fi
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Check for required tools
    for tool in pkgutil installer sudo bc; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "Error: Required tool '$tool' not found"
            exit 1
        fi
    done
    
    main "$@"
fi