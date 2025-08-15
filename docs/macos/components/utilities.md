# Shared Utilities

Common utilities and functions used across multiple components.

## What it provides

Reusable functions and utilities to avoid code duplication across components.

---

## Scripts

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

---

## Benefits

- **Consistency**: Same behavior across all components
- **Maintainability**: Updates in one place affect all components
- **Reliability**: Well-tested functions reduce component-specific bugs
- **Standardization**: Common patterns for error messages and logging