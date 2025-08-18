# Component Documentation

Auto-generated documentation from script docstrings.

## Table of Contents

- [Diagnostics](#diagnostics)
- [IDE](#ide)
- [LaTeX](#latex)
- [Orchestrator](#orchestrator)
- [Package Manager](#package-manager)
- [Python](#python)
- [Utilities](#utilities)
- [VSCode](#vscode)

## Diagnostics

### System Diagnostics

Comprehensive system diagnostics for Python development environment on macOS

**File:** `Diagnostics/run.sh`

**Usage:**
```bash
bash run.sh
```

**Notes:** Checks macOS version, architecture, Homebrew, Python installations, conda environments, and VSCode setup


---

## IDE

### VSCode Installation

Installs Visual Studio Code on macOS with Python extension setup

**File:** `VSC/install.sh`

**Usage:**
```bash
bash install.sh
```

**Notes:** Configures remote repository settings and installs via Homebrew cask


---

### VSCode Extensions Installation

Installs essential VSCode extensions for Python development

**File:** `VSC/install_extensions.sh`

**Usage:**
```bash
bash install_extensions.sh
```

**Notes:** Installs Python extension pack and other development tools


---

## LaTeX

### LaTeX Full Installation

Installs complete MacTeX distribution for comprehensive PDF export from Jupyter Notebooks

**File:** `Latex/full_install.sh`

**Usage:**
```bash
bash full_install.sh
```

**Notes:** Downloads full MacTeX (~4GB), includes Jupyter/nbconvert setup, tests PDF export functionality


---

### LaTeX Minimal Installer

Installs BasicTeX with essential packages for PDF export from Jupyter notebooks

**File:** `Latex/minimal_install.sh`

**Requirements:** macOS, Internet connection, Administrator privileges, Python with nbconvert

**Usage:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Latex/minimal_install.sh)"
```

**Example:**
```bash
./minimal_install.sh
```

**Notes:** Installs BasicTeX (~100MB) plus essential packages from original install.sh. Designed for basic PDF export functionality from Jupyter notebooks in VS Code. For advanced LaTeX features, use full_install.sh instead.

*Version: 2024-08-18 | Author: Python Support Team*


---

### LaTeX PDF Export Test

Tests PDF export functionality from Jupyter notebooks using LaTeX

**File:** `Latex/test_pdf_export.sh`

**Usage:**
```bash
bash test_pdf_export.sh
```

**Notes:** Downloads test notebook and verifies PDF export pipeline works correctly


---

## Orchestrator

### First Year Students Setup

Complete installation orchestrator for DTU first year students - installs Homebrew, Python, VSCode, and LaTeX

**File:** `orchestrators/first_year_students.sh`

**Usage:**
```bash
bash first_year_students.sh
```

**Notes:** Includes Piwik analytics tracking, comprehensive error handling, and component verification


---

## Package Manager

### Homebrew Installation

Installs Homebrew package manager on macOS with error handling and user guidance

**File:** `Homebrew/install.sh`

**Usage:**
```bash
bash install.sh
```

**Notes:** Uses shared utilities for consistent error handling and logging


---

## Python

### Python First Year Setup

Sets up Python environment with conda for DTU first year students

**File:** `Python/first_year_setup.sh`

**Usage:**
```bash
bash first_year_setup.sh
```

**Notes:** Installs miniconda, creates base environment with Python 3.11, installs essential packages


---

### Python Component Installer

Installs Python via Miniconda with essential packages for data science and academic work

**File:** `Python/install.sh`

**Requirements:** macOS, Internet connection, Homebrew (will be installed if missing)

**Usage:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/install.sh)"
```

**Example:**
```bash
PYTHON_VERSION_PS=3.11 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/.../Python/install.sh)"
```

**Notes:** Script automatically installs Homebrew if not present. Supports multiple Python versions via PYTHON_VERSION_PS environment variable. Creates conda environments and installs essential data science packages.

*Version: 2024-08-18 | Author: Python Support Team*


---

### Conda Uninstaller

Completely removes conda/miniconda installations from macOS

**File:** `Python/uninstall_conda.sh`

**Usage:**
```bash
bash uninstall_conda.sh
```

**Notes:** Removes both Anaconda and Miniconda installations, cleans configuration files and PATH modifications


---

### Python Uninstaller

Removes Python installations and related files from macOS system

**File:** `Python/uninstall_python.sh`

**Usage:**
```bash
bash uninstall_python.sh
```

**Notes:** Removes Python from multiple locations including Library, Applications, and system paths. Requires sudo access.


---

## Utilities

### Dependency Management Utilities

Functions for checking and installing system dependencies like Homebrew and conda

**File:** `Shared/dependencies.sh`

**Usage:**
```bash
source dependencies.sh
```

**Notes:** Provides automated dependency installation and verification functions


---

### Environment Setup Utilities

Environment variable management and system configuration functions

**File:** `Shared/environment.sh`

**Usage:**
```bash
source environment.sh
```

**Notes:** Handles REMOTE_PS/BRANCH_PS variables, URL construction, and environment validation


---

### Error Handling Utilities

Standardized error handling, logging, and user messaging functions

**File:** `Shared/error_handling.sh`

**Usage:**
```bash
source error_handling.sh
```

**Notes:** Provides consistent error messages, logging levels, and exit handling across all scripts


---

### Utility Loader

Master loader that sources all Python Support utility modules

**File:** `Shared/load_utils.sh`

**Usage:**
```bash
source load_utils.sh
```

**Notes:** Automatically loads error_handling, environment, dependencies, and remote_utils modules


---

### Piwik Installation Simulator

Testing utility that simulates installation events for Piwik analytics validation

**File:** `Shared/piwik_installation_simulator.sh`

**Usage:**
```bash
bash piwik_installation_simulator.sh
```

**Notes:** Used for testing and validating Piwik analytics tracking without running actual installations


---

### Piwik Analytics Utility

Analytics tracking utility for monitoring installation script usage and success rates

**File:** `Shared/piwik_utility.sh`

**Usage:**
```bash
source piwik_utility.sh; piwik_log "event_name" command args
```

**Notes:** Tracks installation events to Piwik PRO for usage analytics and error monitoring


---

### Remote Script Utilities

Functions for safely downloading and sourcing remote scripts and files

**File:** `Shared/remote_utils.sh`

**Usage:**
```bash
source remote_utils.sh
```

**Notes:** Provides secure remote script execution and file downloading capabilities


---

### Shared Utilities

Common utility functions used across all Python Support installation scripts

**File:** `Shared/utils.sh`

**Usage:**
```bash
source utils.sh
```

**Notes:** Provides error handling, logging, and common functionality for all components


---

## VSCode

### VS Code Clean Uninstaller

Completely removes Visual Studio Code and all user data according to official documentation

**File:** `VSC/clean_uninstall.sh`

**Requirements:** macOS, Administrator privileges

**Usage:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/VSC/clean_uninstall.sh)"
```

**Example:**
```bash
./clean_uninstall.sh
```

**Notes:** Removes VS Code application, user settings folder (~/.vscode), and application support data (~/Library/Application Support/Code). Also handles Homebrew-installed VS Code. This follows the official VS Code uninstall documentation exactly.

*Version: 2024-08-18 | Author: Python Support Team*


---

