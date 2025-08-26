# DTU Python Support Scripts
## Installation

### macOS

**Option 1: Download and Run (Recommended)** - Download the GUI installer:
- <a href="#" onclick="downloadFile('https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/releases/dtu-python-installer-macos-gui.sh', 'dtu-python-installer-macos.sh')">Download macOS GUI Installer</a>
- Download the file, then double-click to run

<script>
function downloadFile(url, filename) {
    fetch(url)
        .then(response => response.blob())
        .then(blob => {
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.style.display = 'none';
            a.href = url;
            a.download = filename;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
        });
}
</script>

**Option 2: GUI Mode** - Uses native macOS authentication dialogs:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/releases/dtu-python-installer-macos.sh)"
```

**Option 3: CLI Mode** - Uses terminal prompts for authentication:
```bash
curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/releases/dtu-python-installer-macos.sh | bash -s -- --cli
```

### Windows

**Option 1: Download and Run (Recommended)** - Download the Windows GUI installer:
- <a href="#" onclick="downloadFile('https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Windows/releases/dtu-python-installer-windows-gui.bat', 'dtu-python-installer-windows.bat')">Download Windows GUI Installer</a>
- Download the file, then double-click to run

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
```
