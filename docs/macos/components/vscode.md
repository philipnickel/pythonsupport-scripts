# VSCode Component

Installs Visual Studio Code and essential extensions for Python development.

---

## Overview

This component provides scripts for installing Visual Studio Code and configuring it with essential extensions for Python development.

---

## Installation Scripts

### Main VSCode Installation Script

**Path:** `MacOS/Components/VSC/install.sh`

**Usage:** `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/VSC/install.sh)"`

**Description:** Main installation script for Visual Studio Code.

**Requirements:**

- Working Homebrew installation

**Expected Outcome:**

- VSCode installed and accessible via `code` command
- Application available in `/Applications`

---

### VSCode Extensions Installation Script

**Path:** `MacOS/Components/VSC/install_extensions.sh`

**Usage:** `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/VSC/install_extensions.sh)"`

**Description:** Installs recommended extensions for Python development.

**Extensions Installed:**

- Python (Microsoft)
- Jupyter
- PDF Viewer

**Requirements:**

- VSCode installation present (and 'code' command available in terminal)

**Expected Outcome:**

- All specified extensions installed and ready for use