# Python Component

📖 **This content has been moved to auto-generated documentation: [Python Components](../../generated/components.md#python)**

The auto-generated docs include:
- **Python Installation**: Main Miniconda setup
- **Python First Year Setup**: Environment configuration for DTU students
- Usage examples, requirements, and notes extracted directly from scripts

---

## Installation Scripts

### Main Miniconda Installation Script

**Path:** `MacOS/Components/Python/install.sh`

**Usage:** `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/install.sh)"`

**Description:** Main installation script that sets up Miniconda with proper configuration for Python development.

**What it does:**

1. **Dependency Check**: Ensures Homebrew is installed
2. **Miniconda Installation**: Installs Miniconda via Homebrew cask
3. **Shell Configuration**: Initializes conda for bash and zsh
4. **Channel Configuration**: 
   - Removes default channels (licensing concerns)
   - Adds conda-forge channel
   - Sets flexible channel priority

**Requirements:**

- Working Homebrew installation

**Expected Outcome:**

- `python3` command runs Python through Miniconda
- `conda` command available and configured
- Shell initialization complete for future sessions

---

### Setup script for first-year students

**Path:** `MacOS/Components/Python/first_year_setup.sh`

**Usage:** `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/first_year_setup.sh)"`

**Description:** Installs specific Python version and packages for first-year courses.

**Packages Installed:**

- dtumathtools
- pandas
- scipy
- statsmodels
- uncertainties

**Requirements:**

- Working conda installation

**Expected Outcome:**

- Specific packages installed in base environment

---

### Setup script for specific courses

**Path:** `MacOS/Components/Python/env_setup.sh`

**Usage:** `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/env_setup.sh)"`

**Description:** Installs a specific conda environment from a yaml file.

**Requirements:**

- Working conda installation

**Expected Outcome:**

- Specific conda environment installed from a yaml file

---

## Uninstallation Scripts

### Uninstall Miniconda

**Path:** `MacOS/Components/Python/uninstall_conda.sh`

**Usage:** `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/uninstall_conda.sh)"`

**Description:** Removes Miniconda installation and configuration.

**Requirements:**

- Miniconda installation present

**Expected Outcome:**

- Miniconda completely removed from system

---

### Uninstall 'standard' Python installations

**Path:** `MacOS/Components/Python/uninstall_python.sh`

**Usage:** `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/uninstall_python.sh)"`

**Description:** Removes 'standard' Python installations.

**Requirements:**

- Standard Python installation present

**Expected Outcome:**

- Standard Python installations removed from system 
