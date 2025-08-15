# LaTeX Component

Installs MacTeX (TeXLive distribution) for LaTeX document preparation.

## What it does

1. **Dependency Check**: Ensures Homebrew is installed
2. **MacTeX Installation**: Installs full TeXLive distribution via Homebrew
3. **Path Configuration**: Adds TeX binaries to PATH
4. **Verification**: Tests that `pdflatex` and other tools work

## Requirements

- MacTeX is a large installation (~4GB)
- Installation can take significant time depending on network
- Working python installation

---

## Scripts

### `install.sh`

Main installation script for MacTeX.

**Installation Process:**

- Installs `mactex` cask via Homebrew
- Large download (~4GB) - includes full TeXLive
- Updates PATH for TeX binaries

**Expected Outcome:**

- Full TeXLive distribution installed
- VSCode pdf-export configuration for LaTeX

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