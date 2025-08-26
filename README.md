# Python Support Scripts

📚 **[View Complete Documentation](https://philipnickel.github.io/pythonsupport-scripts/)**

This repository contains automated installation scripts for Python development environments and associated tools for macOS and Windows.

## Quick Installation

### macOS
Open Terminal (⌘ + Space, search "Terminal") and run:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/install.sh)"
```

### Windows
Open PowerShell as Administrator (Windows + X, select "Windows PowerShell (Admin)") and run:
```powershell
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/Windows/install.ps1" -UseBasicParsing).Content
```

## Diagnostics

Check your Python environment installation:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/Components/Diagnostics/simple_report.sh)"
```
