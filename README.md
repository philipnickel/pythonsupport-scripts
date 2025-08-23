# Python Support Scripts

📚 **[View Complete Documentation](https://philipnickel.github.io/pythonsupport-scripts/)**

This repository contains automated installation scripts for Python development environments and associated tools for macOS and Windows.

## 🚀 New: Constructor-Based Installer

We now offer a **simplified, reliable installer** built with Constructor:

```bash
# Build the installer locally
cd constructor_installer
./build.sh

# The installer will be created in dist/
```

**Key Benefits:**
- ✅ **Simplified**: No complex scripts or manual configuration
- ✅ **Reliable**: Uses conda's native package management
- ✅ **Clean**: Only conda-forge channels (no ToS issues)
- ✅ **Standard**: Follows conda best practices

See [constructor_installer/README.md](constructor_installer/README.md) for details.

## System Status

https://github.com/philipnickel/pythonsupport-scripts/blob/main/main_controller.txt

> **Note**: To disable components quickly, edit [main_controller.txt](main_controller.txt). This configuration is used by administrators to control system availability.

## Quick Diagnostics

The diagnostics system now supports targeted testing profiles for different needs:

### First Year Environment (Single Comprehensive Test)
Perfect for DTU first year students - one comprehensive test covering all essential requirements:
```bash
curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/Components/Diagnostics/generate_report.sh | bash -s -- --profile first_year
```

### Comprehensive Environment (All Tests)
Complete diagnostic suite for advanced users and troubleshooting:
```bash
curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/Components/Diagnostics/generate_report.sh | bash -s -- --profile comprehensive
```

### Local Usage
If you have the repository cloned locally:
```bash
cd MacOS/Components/Diagnostics
./generate_report.sh --profile first_year        # Single comprehensive test
./generate_report.sh --profile comprehensive     # All tests (default)
./generate_report.sh --help                      # View available profiles
```
