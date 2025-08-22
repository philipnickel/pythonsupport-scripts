# Python Support Scripts

📚 **[View Complete Documentation](https://philipnickel.github.io/pythonsupport-scripts/)**

This repository contains automated installation scripts for Python development environments and associated tools for macOS and Windows.

## System Status

https://github.com/philipnickel/pythonsupport-scripts/blob/main/main_controller.md

> **Note**: To disable components quickly, edit [main_controller.md](main_controller.md). This table is used by administrators to communicate system availability.

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
