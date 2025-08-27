# DTU Python Support Scripts
## Installation

### macOS

#### Active: 
**Terminal oneliner**  
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/releases/dtu-python-installer-macos.sh)"
```

### Windows

**PowerShell oneliner** - Uses native Windows UAC authentication:
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

### macOS VS Code Uninstaller
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/VSC/uninstall_vscode.sh)"
```

### Windows Diagnostics
```powershell
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/windows_report/Windows/Components/Diagnostics/simple_report.ps1" -UseBasicParsing).Content
```

### Windows Comprehensive Report Generator
```powershell
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/windows_report/Windows/Components/Diagnostics/generate_report.ps1" -UseBasicParsing).Content
```