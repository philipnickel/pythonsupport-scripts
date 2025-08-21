# DTU Python PKG Installer - Test Checklist

## Quick Reference for Testing the PKG Installer

### Pre-Test Verification

- [ ] PKG file exists: `/Users/philipnickel/Documents/GitHub/pythonsupport-scripts/MacOS/pkg_installer/builds/DtuPythonInstaller_1.0.59.pkg`
- [ ] File size is reasonable (40-50KB expected)
- [ ] XAR archive format confirmed: `file *.pkg` shows "xar archive"
- [ ] Test scripts are executable: `chmod +x *.sh`

### Structure Validation (Safe - No Installation)

Run these commands to validate PKG structure without installing:

```bash
cd /Users/philipnickel/Documents/GitHub/pythonsupport-scripts/MacOS/pkg_installer

# Quick structure check
./quick_test.sh

# Comprehensive validation  
./validate_pkg_structure.sh
```

**Expected Results**:
- [ ] All 4/4 basic structure checks pass
- [ ] 25+ bundled shell scripts detected
- [ ] Key components present: Distribution, Scripts, Payload, PackageInfo
- [ ] Main orchestrator bundled: `orchestrators/first_year_students.sh`
- [ ] Essential scripts bundled: `Python/install.sh`, `VSC/install.sh`, etc.

### Full Installation Test (⚠️ Test System Only)

**WARNING**: This actually installs the PKG and modifies the system.

```bash
cd /Users/philipnickel/Documents/GitHub/pythonsupport-scripts/MacOS/pkg_installer

# Full installation test
sudo ./test_pkg_installer.sh
```

### Installation Success Criteria

- [ ] **PKG Installation**: `sudo installer -pkg *.pkg -target /` succeeds
- [ ] **Postinstall Execution**: Log created at `/tmp/macos_dtu_python_install.log`
- [ ] **PKG Mode Detection**: Log contains "Environment detected: PKG mode"
- [ ] **Bundled Components**: Components accessible at `/usr/local/share/dtu-python-installer/components`
- [ ] **No Network Requests**: Log confirms "No network dependencies were used"

### Functionality Verification (Matching mac_orchestrators.yml)

After installation, verify these commands work:

```bash
# Conda verification
which conda                    # Must return path
conda --version               # Must show version
conda info --base            # Must show base directory

# Python 3.11 verification  
python3 --version            # Must return 3.11.x
[[ "$(python3 --version | cut -d " " -f 2)" == "3.11"* ]] && echo "PASS" || echo "FAIL"

# Package import test (exact same as mac_orchestrators.yml)
python3 -c "import dtumathtools, pandas, scipy, statsmodels, uncertainties; print('Packages imported successfully')"

# VS Code verification
code --version               # Must show VS Code version
```

**Expected Results**:
- [ ] Conda command available and working
- [ ] Python version is exactly 3.11.x
- [ ] All 5 packages import without errors  
- [ ] VS Code command available

### Test Results Documentation

**Success Indicators**:
- [ ] All structure validation checks pass (4/4)
- [ ] PKG installs without installer errors
- [ ] Postinstall script detects PKG mode correctly
- [ ] All functionality tests match mac_orchestrators.yml expectations
- [ ] No network requests made during installation
- [ ] Installation log shows successful component loading

**Test Logs to Review**:
- [ ] PKG validation log: `/tmp/pkg_validation_*.log`
- [ ] Installation test log: `/tmp/pkg_installer_test_*.log`
- [ ] System installation log: `/tmp/macos_dtu_python_install.log`
- [ ] Installation summary: `/tmp/macos_dtu_python_summary.txt`

### Comparison with Traditional Method

Verify PKG results match traditional installation from mac_orchestrators.yml:

| Component | Traditional Result | PKG Result | Match? |
|-----------|-------------------|------------|--------|
| Conda | Available via `which conda` | Available via `which conda` | [ ] |
| Python | 3.11.x via `python3 --version` | 3.11.x via `python3 --version` | [ ] |
| Packages | Import successfully | Import successfully | [ ] |
| VS Code | Available via `code --version` | Available via `code --version` | [ ] |

### Environment Detection Test

Verify PKG mode vs traditional mode detection:

```bash
# Check PKG mode environment variables (after installation)
echo $DTU_PYTHON_PKG_MODE        # Should be "true" during installation
ls -la /usr/local/share/dtu-python-installer/components  # Should exist with 25+ files
grep "PKG mode" /tmp/macos_dtu_python_install.log        # Should show PKG mode detection
```

- [ ] PKG mode correctly detected during installation
- [ ] Bundled components used instead of network requests
- [ ] Environment variables set correctly
- [ ] Curl wrapper created and used for component loading

### Cleanup Options (Optional)

If you need to remove the installation for retesting:

```bash
# Remove bundled components
sudo rm -rf /usr/local/share/dtu-python-installer

# Remove conda (use provided script)
./MacOS/Components/Python/uninstall_conda.sh

# Remove VS Code (manual app deletion)

# Remove Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
```

### Final Validation Checklist

**PKG Installer is Ready for Production When**:

- [ ] All structure validation tests pass
- [ ] PKG installs successfully without errors
- [ ] PKG mode detection works correctly  
- [ ] All bundled components are accessible
- [ ] No network dependencies during installation
- [ ] Final environment matches mac_orchestrators.yml exactly
- [ ] All functionality tests pass (conda, python, packages, vscode)
- [ ] Installation logs show successful completion
- [ ] Test results documented and reviewed

**Sign-off**: 
- [ ] Developer tested and verified
- [ ] Test logs reviewed and approved
- [ ] PKG ready for release

---

## Quick Commands Summary

```bash
# Navigate to PKG directory
cd /Users/philipnickel/Documents/GitHub/pythonsupport-scripts/MacOS/pkg_installer

# Quick validation (safe)
./quick_test.sh

# Full structure validation (safe)
./validate_pkg_structure.sh

# Complete installation test (⚠️ modifies system)
sudo ./test_pkg_installer.sh

# Check installation logs
tail -f /tmp/macos_dtu_python_install.log

# Verify final environment
which conda && python3 --version && code --version
python3 -c "import dtumathtools, pandas, scipy, statsmodels, uncertainties"
```