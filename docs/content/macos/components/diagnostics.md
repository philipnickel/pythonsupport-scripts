# Diagnostics Component

📖 **This content has been moved to auto-generated documentation: [System Diagnostics](../../generated/components.md#system-diagnostics)**

The auto-generated docs include:
- Comprehensive system analysis and compatibility checks
- macOS version, architecture, and environment verification  
- Usage examples and requirements extracted directly from scripts

---

## Scripts

### `run.sh`

Main diagnostics script that performs all system checks.

**Checks Performed:**

- macOS version compatibility
- Available disk space
- Existing Python installations (ordinary python, miniconda, conda etc.)
- Homebrew installation status

**Output:**

- Detailed system report
- Compatibility warnings
- Outputs to a temporary file in home directory

---

## Usage

Run before any installation to identify potential issues:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Diagnostics/run.sh)"
```

---

## Integration

- Used within the GUI to check system compatibility before installation and to check if the installation was successful.
- Output file integrated into GUI mail-to functionality 
