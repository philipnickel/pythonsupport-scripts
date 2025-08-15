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

**Functions Available:**

- `piwik_log(event_name, [result])`: Track an installation event with optional result status
- `get_system_info()`: Collect system information (OS, architecture, version)

**Usage in Components:**

```bash
# Source the utility
source MacOS/Components/Shared/piwik_utility.sh

# Track installation events
piwik_log "Python_Installation_Start"
piwik_log "Python_Installation_Success"
piwik_log "Python_Installation_Failed" "network_error"
piwik_log "VS_Code_Installation_Cancelled" "user_cancelled"
```

**Environment Variables:**

- `TESTING_MODE=true`: Use "Installer_TEST" category instead of "Installer" (for testing)
- `DISABLE_ANALYTICS=true`: Disable all tracking
- `DISABLE_PIWIK=true`: Disable Piwik tracking

**Event Categories:**
- **Production**: `Installer` (default)
- **Testing**: `Installer_TEST` (when `TESTING_MODE=true`)

**Session Dimensions Tracked:**
- **Operating System**: macOS version and architecture
- **Architecture**: System architecture (x86_64, arm64, etc.)
- **Script Version**: Version of the utility script

**Example Events:**
```bash
# Installation lifecycle
piwik_log "Python_Installation_Start"
piwik_log "Python_Installation_Success"
piwik_log "Python_Installation_Failed" "permission_denied"

# Component-specific events
piwik_log "Homebrew_Installation_Success"
piwik_log "VS_Code_Extension_Installation_Failed" "network_error"
piwik_log "LaTeX_Installation_Cancelled" "user_cancelled"
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