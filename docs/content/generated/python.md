# Python Components

Documentation for Python installation scripts.

## Python First Year Setup

**Description:** Sets up Python environment with conda for DTU first year students

**Usage:**
```bash
bash first_year_setup.sh
```

**Requirements:** macOS system, Homebrew

**Notes:** Installs miniconda, creates base environment with Python 3.11, installs essential packages

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/first_year_setup.sh)"
```

---

## Python Component Installer

**Description:** Installs Python via Miniconda with essential packages for data science and academic work

**Usage:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/install.sh)"
```

**Notes:** Script automatically installs Homebrew if not present. Supports multiple Python versions via PYTHON_VERSION_PS environment variable. Creates conda environments and installs essential data science packages.

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/install.sh)"
```

---

## Conda Uninstaller

**Description:** Completely removes conda/miniconda installations from macOS

**Usage:**
```bash
bash uninstall_conda.sh
```

**Requirements:** macOS system, existing conda installation

**Notes:** Removes both Anaconda and Miniconda installations, cleans configuration files and PATH modifications

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/uninstall_conda.sh)"
```

---

## Python Uninstaller

**Description:** Removes Python installations and related files from macOS system

**Usage:**
```bash
bash uninstall_python.sh
```

**Requirements:** macOS system with admin privileges

**Notes:** Removes Python from multiple locations including Library, Applications, and system paths. Requires sudo access.

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/uninstall_python.sh)"
```

---

