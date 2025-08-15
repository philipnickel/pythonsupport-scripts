# Shared Utilities

Common utilities and functions used across multiple components.

## What it provides

Reusable functions and utilities to avoid code duplication across components.

---

## Scripts

### `MacOS/Components/Shared/piwik_utility.sh`

Analytics tracking utility for monitoring installation events and system information.

**Purpose:**
Track installation events, system information, and user interactions to improve the installation experience and identify common issues.

**Usage:**
Replace any command with `piwik_log` to automatically track its execution:

```bash
# Source the utility
source MacOS/Components/Shared/piwik_utility.sh

# Instead of:
python_install_command

# Use:
piwik_log 'python_installation' python_install_command
```

**Environment Variables:**

- `TESTING_MODE=true`: Use "Installer_TEST" category (for testing/development)
- `GITHUB_CI=true`: Use "Installer_CI" category (for GitHub workflows)

**Event Categories:**
- **Local Development**: `Installer` (default)
- **Testing**: `Installer_TEST` (when `TESTING_MODE=true`)
- **CI/Production**: `Installer_CI` (when `GITHUB_CI=true`)

**What Gets Tracked:**
- **Event Name**: The name you provide (e.g., 'python_installation')
- **Event Value**: 1 for success, 0 for failure
- **Event Category**: Based on environment variables
- **System Info**: OS, architecture, commit SHA
- **Error Messages**: Full error output when commands fail

**Example Usage in Components:**

```bash
#!/bin/bash
source MacOS/Components/Shared/piwik_utility.sh

# Python installation
piwik_log 'python_download' curl -L https://www.python.org/ftp/python/3.11.0/python-3.11.0-macos11.pkg -o python.pkg
piwik_log 'python_install' sudo installer -pkg python.pkg -target /

# VS Code installation
piwik_log 'vscode_download' curl -L https://code.visualstudio.com/sha/download?build=stable&os=darwin-universal -o vscode.zip
piwik_log 'vscode_extract' unzip vscode.zip -d /Applications/

# Homebrew installation
piwik_log 'homebrew_install' /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**GitHub Workflow Example:**

```yaml
name: Install Python Support
on: [push, pull_request]

jobs:
  install:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Python Support
        env:
          GITHUB_CI: true
        run: |
          source MacOS/Components/Shared/piwik_utility.sh
          piwik_log 'python_install' brew install python
          piwik_log 'vscode_install' brew install --cask visual-studio-code
```

### `MacOS/Components/Utilities/utils.sh`

Common utility functions that can be sourced by other scripts.

**Functions Available:**

- `log_message()`: Standardized logging with timestamps
- `backup_file()`: Create backups of configuration files
- `update_shell_profile()`: Safely update shell configuration files
- `cleanup_temp_files()`: Remove temporary installation files

**Usage in Components:**

```bash
source /dev/stdin <<< "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Utilities/utils.sh)"
```

---

## Integration

Components can leverage shared utilities for:

- Consistent error handling
- Standardized logging
- Common system checks
- File backup and recovery
- **Analytics tracking** for installation events

---

## Benefits

- **Consistency**: Same behavior across all components
- **Maintainability**: Updates in one place affect all components
- **Reliability**: Well-tested functions reduce component-specific bugs
- **Standardization**: Common patterns for error messages and logging
- **Analytics**: Track installation success rates and identify common issues
- **Simplicity**: Just wrap commands with `piwik_log` for automatic tracking
- **Flexibility**: Different event categories for different environments (local, testing, CI)