# DTU Python Support - Windows Release Scripts

This directory contains ready-to-use Windows batch files (.bat) that provide one-click installation of Python environments for different course levels at DTU.

## Available Installers

### 🎓 First Year Students - `install_first_year.bat`
**Recommended for:** Introduction courses, basic Python programming

**Includes:**
- Python 3.11 (Miniforge distribution)
- Visual Studio Code with Python extensions
- Essential packages:
  - `dtumathtools` - DTU-specific mathematical tools
  - `pandas` - Data manipulation and analysis
  - `scipy` - Scientific computing
  - `statsmodels` - Statistical modeling
  - `uncertainties` - Uncertainty calculations

### 🔬 Advanced/Later Years - `install_advanced.bat`
**Recommended for:** Advanced courses, research projects, data science

**Includes:**
- Everything from first year setup
- Additional packages:
  - `matplotlib` - Plotting and visualization
  - `seaborn` - Statistical data visualization
  - `scikit-learn` - Machine learning
  - `jupyter` - Interactive notebooks
  - `notebook` - Jupyter notebook interface
  - `ipykernel` - IPython kernel for Jupyter

## How to Use

### Method 1: Direct Download and Run
1. Download the appropriate `.bat` file
2. Double-click to run
3. Follow the installation prompts

### Method 2: Command Line
1. Open Command Prompt or PowerShell
2. Navigate to the folder containing the `.bat` file
3. Run: `install_first_year.bat` or `install_advanced.bat`

## System Requirements

- **Operating System:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or later (usually pre-installed)
- **Internet Connection:** Required for downloading components
- **Disk Space:** At least 2GB free space
- **Administrator Rights:** Not required (installs to user profile)

## What Gets Installed

### Directory Structure
```
%USERPROFILE%\miniforge3\        # Python distribution
%USERPROFILE%\AppData\Local\Programs\Microsoft VS Code\  # VS Code
```

### Environment Setup
- Creates a conda environment called `first_year`
- Adds Python and conda to your PATH
- Configures VS Code with Python extensions

## Troubleshooting

### Common Issues

**PowerShell Execution Policy Error:**
- The installer automatically sets the execution policy
- If you see errors, run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force`

**Download Failures:**
- Check your internet connection
- Try disabling antivirus temporarily
- Run as administrator if needed

**VS Code Not Found After Installation:**
- Restart your Command Prompt/PowerShell
- Log out and log back in to Windows
- Check if VS Code is in Start Menu

### Getting Help

- **Documentation:** https://pythonsupport.dtu.dk
- **Email Support:** pythonsupport@dtu.dk
- **GitHub Issues:** https://github.com/dtudk/pythonsupport-scripts/issues

## For Developers

These batch files are wrappers around the main PowerShell installer at `Windows/install.ps1`. They:

1. Set appropriate parameters for different course levels
2. Handle basic error checking and user feedback
3. Provide a user-friendly interface for non-technical users
4. Can be easily customized for specific course requirements

### Customizing for Your Course

To create a custom installer:
1. Copy `install_first_year.bat` to `install_your_course.bat`
2. Modify the package list in the PowerShell command
3. Update the description and echo statements
4. Test thoroughly before distribution

## Security Note

These scripts download and execute code from the internet. They use HTTPS and verify the source, but users should only run installers from trusted sources like the official DTU Python Support repository.