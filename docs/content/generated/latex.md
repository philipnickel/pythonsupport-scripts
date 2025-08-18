# Latex Components

Documentation for Latex installation scripts.

## LaTeX Full Installation

**Description:** Installs complete MacTeX distribution for comprehensive PDF export from Jupyter Notebooks

**Usage:**
```bash
bash full_install.sh
```

**Requirements:** macOS system, conda environment (recommended), ~4GB disk space

**Notes:** Downloads full MacTeX (~4GB), includes Jupyter/nbconvert setup, tests PDF export functionality

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Latex/full_install.sh)"
```

---

## LaTeX Minimal Installer

**Description:** Installs BasicTeX with essential packages for PDF export from Jupyter notebooks

**Usage:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Latex/minimal_install.sh)"
```

**Notes:** Installs BasicTeX (~100MB) plus essential packages from original install.sh. Designed for basic PDF export functionality from Jupyter notebooks in VS Code. For advanced LaTeX features, use full_install.sh instead.

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Latex/minimal_install.sh)"
```

---

## LaTeX PDF Export Test

**Description:** Tests PDF export functionality from Jupyter notebooks using LaTeX

**Usage:**
```bash
bash test_pdf_export.sh
```

**Requirements:** LaTeX installation, Python with nbconvert, Jupyter

**Notes:** Downloads test notebook and verifies PDF export pipeline works correctly

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Latex/test_pdf_export.sh)"
```

---

