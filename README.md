# Python Support Scripts

📚 **[View Complete Documentation](https://philipnickel.github.io/pythonsupport-scripts/)**

This repository contains automated installation scripts for Python development environments and associated tools for macOS and Windows.

## Quick Installation

### macOS
Open Terminal (⌘ + Space, search "Terminal") and run:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/releases/dtu-python-installer-macos.sh)"
```

### Windows
Open PowerShell as Administrator (Windows + X, select "Windows PowerShell (Admin)") and run:
```powershell
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/Windows/install.ps1" -UseBasicParsing).Content
```

## Diagnostics

Check your Python environment installation:

```bash
REMOTE_PS="philipnickel/pythonsupport-scripts" BRANCH_PS="MacOS_DEV" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/MacOS_DEV/MacOS/Components/Diagnostics/simple_report.sh)"
```

For testing with your development branch. The default version (using dtudk repo and main branch):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Diagnostics/simple_report.sh)"
```
