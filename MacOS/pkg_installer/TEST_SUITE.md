# DTU Python PKG Installer - Comprehensive Test Suite

This directory contains a complete test suite for validating the DTU Python PKG installer, ensuring it works correctly and passes the same tests as the traditional installation method used in `mac_orchestrators.yml`.

## Test Files

### 1. `test_pkg_installer.sh` - Full Installation Test
**Purpose**: Comprehensive end-to-end testing of the actual PKG installation process.

**What it tests**:
- ✅ PKG file integrity and installation
- ✅ Postinstall script execution and PKG mode detection  
- ✅ Bundled components accessibility
- ✅ Environment detection (PKG vs traditional mode)
- ✅ Network isolation verification (no curl to GitHub)
- ✅ Functionality verification matching `mac_orchestrators.yml`:
  - Conda installation: `which conda` and `conda --version`
  - Python 3.11: `python3 --version` returns 3.11.x
  - Package imports: `python3 -c "import dtumathtools, pandas, scipy, statsmodels, uncertainties"`
  - VS Code: `code --version`

**Usage**:
```bash
sudo ./test_pkg_installer.sh
```

**Note**: This actually installs the PKG, so use on a test system or VM.

### 2. `validate_pkg_structure.sh` - Non-destructive Validation
**Purpose**: Validates PKG structure and contents without installing anything.

**What it tests**:
- ✅ PKG file structure and metadata
- ✅ Bundled components presence and organization
- ✅ Script syntax validation
- ✅ PKG mode compatibility features
- ✅ Expected installation behavior analysis

**Usage**:
```bash
./validate_pkg_structure.sh
```

**Note**: Safe to run anywhere - doesn't install anything.

## Test Results Comparison

The test suite ensures the PKG installer produces identical results to the traditional installation method tested in GitHub Actions `mac_orchestrators.yml`:

| Test Category | Traditional Method | PKG Installer | Status |
|---------------|-------------------|---------------|--------|
| Conda Installation | `which conda` succeeds | `which conda` succeeds | ✅ Match |
| Python Version | `python3 --version` → 3.11.x | `python3 --version` → 3.11.x | ✅ Match |
| Package Imports | All packages import successfully | All packages import successfully | ✅ Match |
| VS Code | `code --version` succeeds | `code --version` succeeds | ✅ Match |
| Network Dependencies | Uses curl to GitHub | Uses bundled components | ✅ Improved |

## Key Features Tested

### Environment Detection
The PKG installer automatically detects its execution environment:
- **PKG Mode**: Uses bundled components from `/usr/local/share/dtu-python-installer/components`
- **Traditional Mode**: Falls back to curl-based downloads from GitHub

### Network Isolation  
In PKG mode, the installer:
- Creates a curl wrapper that redirects GitHub requests to local files
- Ensures zero network dependencies during component loading
- Validates that no unexpected network requests occur

### Bundled Components
The PKG includes all necessary components:
- Main orchestrator: `orchestrators/first_year_students.sh`
- Installation scripts: `Python/install.sh`, `VSC/install.sh`, etc.
- Shared utilities: `Shared/master_utils.sh`
- Environment setup: `Python/first_year_setup.sh`

## Running the Tests

### Quick Validation (Recommended first step)
```bash
cd MacOS/pkg_installer
./validate_pkg_structure.sh
```

### Full Installation Test (Test/VM system recommended)
```bash
cd MacOS/pkg_installer  
sudo ./test_pkg_installer.sh
```

## Test Output

Both scripts generate detailed logs and reports:
- **Logs**: `/tmp/pkg_[validation|installer]_test_YYYYMMDD_HHMMSS.log`
- **Results**: `/tmp/pkg_[validation|installer]_test_results_YYYYMMDD_HHMMSS.txt`

Example output:
```
=== PKG INSTALLATION TEST ===
[PASS] PKG installation completed without errors
[PASS] PKG mode correctly detected by postinstall script
[PASS] Bundled components correctly used
[PASS] Main orchestrator script is bundled

=== FUNCTIONALITY VERIFICATION ===
[PASS] Conda found: /opt/homebrew/bin/conda
[PASS] Correct Python version installed: 3.11.9
[PASS] All required packages imported successfully
[PASS] VS Code installed: 1.95.0
```

## Success Criteria

The PKG installer passes all tests when:
1. ✅ PKG installs without errors
2. ✅ Postinstall script detects PKG mode
3. ✅ All bundled components are accessible
4. ✅ No network requests to GitHub during installation
5. ✅ Final environment matches `mac_orchestrators.yml` expectations:
   - Conda command available
   - Python 3.11.x installed
   - Required packages importable
   - VS Code command available

## Cleanup and Uninstall

The test suite provides cleanup guidance but doesn't automatically uninstall to preserve development environments. Manual cleanup options:

```bash
# Remove bundled components
sudo rm -rf /usr/local/share/dtu-python-installer

# Remove conda (use provided script)
./MacOS/Components/Python/uninstall_conda.sh

# Remove VS Code (standard app removal)
# Move VS Code app to trash

# Remove Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
```

## Development and CI Integration

These tests can be integrated into CI/CD pipelines:
- `validate_pkg_structure.sh` for PR validation
- `test_pkg_installer.sh` for release testing on clean VMs

The test results format is compatible with CI reporting tools and provides exit codes for automation:
- Exit 0: All tests passed
- Exit 1: Some tests failed

## Troubleshooting

### Common Issues

1. **PKG not found**: Verify the PKG path in the test scripts matches your build output
2. **Permission denied**: Use `sudo` for the installation test 
3. **Component missing**: Run `validate_pkg_structure.sh` to check bundled components
4. **Network detected**: Indicates PKG mode detection failed or curl wrapper issues

### Debug Information

Both test scripts provide detailed debug output including:
- Environment variables set
- Component paths and file counts
- Installation log excerpts
- Comparison with expected behavior

For support, contact python-support@dtu.dk with test logs and system information.