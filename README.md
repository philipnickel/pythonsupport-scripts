# Python Support Scripts

📚 **[View Complete Documentation](https://philipnickel.github.io/pythonsupport-scripts/)**

This repository contains automated installation scripts for Python development environments and associated tools for macOS and Windows.

## Quick Installation

### macOS
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/releases/dtu-python-installer-macos.sh)"
```

### Windows
```powershell
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/Windows/install.ps1" -UseBasicParsing).Content
```

## Diagnostics

### macOS Diagnostics
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/Components/Diagnostics/simple_report.sh)"
```

### macOS Conda Uninstaller
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/Components/Core/uninstall_conda.sh)"
```
