# Diagnostics Component

Performs system compatibility checks before installation.

## What it does

1. **System Information**: Collects macOS version, hardware details
2. **Compatibility Checks**: Verifies system meets requirements
3. **Existing Software Detection**: Checks for conflicting installations
4. **Resource Availability**: Verifies disk space and memory

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
