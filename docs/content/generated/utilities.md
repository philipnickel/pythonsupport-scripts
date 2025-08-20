# Utilities Components

Documentation for Utilities installation scripts.

## Dependency Management Utilities

**Description:** Functions for checking and installing system dependencies like Homebrew and conda

**Usage:**
```bash
source dependencies.sh
```

**Requirements:** bash shell environment, internet connection

**Notes:** Provides automated dependency installation and verification functions

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Shared/dependencies.sh)"
```

---

## Environment Setup Utilities

**Description:** Environment variable management and system configuration functions

**Usage:**
```bash
source environment.sh
```

**Requirements:** bash shell environment

**Notes:** Handles REMOTE_PS/BRANCH_PS variables, URL construction, and environment validation

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Shared/environment.sh)"
```

---

## Error Handling Utilities

**Description:** Standardized error handling, logging, and user messaging functions

**Usage:**
```bash
source error_handling.sh
```

**Requirements:** bash shell environment

**Notes:** Provides consistent error messages, logging levels, and exit handling across all scripts

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Shared/error_handling.sh)"
```

---

## Master Utility Loader

**Description:** Loads all Python Support utilities including Piwik analytics

**Usage:**
```bash
source master_utils.sh
```

**Requirements:** bash shell environment, internet connection

**Notes:** Sources all utility modules in a single operation

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Shared/master_utils.sh)"
```

---

## Piwik Analytics Utility

**Description:** Analytics tracking utility for monitoring installation script usage and success rates

**Usage:**
```bash
source piwik_utility.sh; piwik_log "event_name" command args
```

**Requirements:** curl, internet connection

**Notes:** Tracks installation events to Piwik PRO for usage analytics and error monitoring

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Shared/piwik_utility.sh)"
```

---

## Remote Script Utilities

**Description:** Functions for safely downloading and sourcing remote scripts and files

**Usage:**
```bash
source remote_utils.sh
```

**Requirements:** curl, internet connection

**Notes:** Provides secure remote script execution and file downloading capabilities

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Shared/remote_utils.sh)"
```

---

## Shared Utilities

**Description:** Common utility functions used across all Python Support installation scripts

**Usage:**
```bash
source utils.sh
```

**Requirements:** bash shell environment

**Notes:** Provides error handling, logging, and common functionality for all components

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Shared/utils.sh)"
```

---

