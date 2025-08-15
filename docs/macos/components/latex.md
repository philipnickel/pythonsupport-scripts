# LaTeX Component

Installs MacTeX (TeXLive distribution) for LaTeX document preparation.

## What it does

1. **Pandoc Installation**: Installs pandoc for document conversion (architecture-specific)
2. **BasicTeX Installation**: Installs lightweight TeXLive distribution  
3. **Package Installation**: Installs additional TeX packages (amsmath, amsfonts, etc.)
4. **Python Integration**: Updates nbconvert for Jupyter notebook PDF export
5. **Non-interactive**: Fully automated with no user prompts

## Requirements

- Working Homebrew installation (automatically installed if missing)
- Working Python installation for nbconvert functionality  
- BasicTeX is smaller than full MacTeX (~500MB vs 4GB)

---

## Scripts

### `install.sh`

Main installation script for MacTeX.

**Installation Process:**

- Fully automated installation (no user prompts)
- Installs pandoc for document conversion
- Installs BasicTeX (lightweight TeXLive distribution)  
- Installs additional TeX packages for document compilation
- Updates nbconvert for Jupyter notebook PDF export

**Expected Outcome:**

- BasicTeX TeXLive distribution installed
- Pandoc available for document conversion
- nbconvert configured for PDF export
- VSCode pdf-export functionality enabled

---

## Usage

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Latex/install.sh)"
```

---

## Notes

- **Size**: MacTeX is a large installation (~4GB)
- **Time**: Installation can take significant time depending on network
- **Multiple python installations/environments**: May not work with every python environment. Sometimes need to reinstall nbconvert in the environment one wishes to use when exporting pdfs. 