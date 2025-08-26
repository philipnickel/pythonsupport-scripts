# DTU Python Support Scripts
## Installation

### macOS

**Option 1: Download and Run (Recommended)** - See [latest release](https://github.com/dtudk/pythonsupport-scripts/releases/latest) for GUI installer.

**Option 2: GUI Mode** - Uses native macOS authentication dialogs:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/releases/dtu-python-installer-macos.sh)"
```

**Option 3: CLI Mode** - Uses terminal prompts for authentication:
```bash
curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/releases/dtu-python-installer-macos.sh | bash -s -- --cli
```

### Windows

**Option 1: Download and Run (Recommended)** - See [latest release](https://github.com/dtudk/pythonsupport-scripts/releases/latest) for Windows GUI installer.

**Option 2: PowerShell** - Uses native Windows UAC authentication:
```powershell
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Windows/install.ps1" -UseBasicParsing).Content
```
## Utilities

### macOS Diagnostics
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Diagnostics/simple_report.sh)"
```

### macOS Conda Uninstaller
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Core/uninstall_conda.sh)"
```
