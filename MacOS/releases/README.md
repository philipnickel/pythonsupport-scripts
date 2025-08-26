# DTU Python Support - Release Files

This folder contains ready-to-use installer files for local testing and future distribution.

## Available Installers

### macOS
- **`dtu-python-installer-macos.sh`** - Complete installer for macOS systems
  - **Current setup**: Configured for `dtudk/pythonsupport-scripts` + `main` branch  
  - **Local testing**: Double-click to run, or `bash dtu-python-installer-macos.sh`
  - **Production**: Will be updated to use `dtudk/pythonsupport-scripts` + `main` when released

## Features
- Automatic conda detection and uninstall prompts
- Python 3.12 installation via Miniforge
- VS Code installation with Python extensions
- DTU-specific packages: dtumathtools, pandas, scipy, statsmodels, uncertainties
- Full verbose output for debugging
- Analytics tracking (with consent)

## CI Integration

CI automatically runs in non-interactive mode when `PIS_ENV=CI` is detected.
Uses the release script for end-to-end testing.

## Customization

Override repository/branch for testing:
```bash
export REMOTE_PS="your-username/pythonsupport-scripts"
export BRANCH_PS="your-branch"
bash dtu-python-installer-macos.sh
```

## Analytics

The installers include optional analytics tracking via Piwik PRO:
- **User installations**: Shows consent dialog (macOS native popup)
- **CI environments**: Analytics enabled automatically
- **Data collected**: Installation success/failure, OS info, timing
- **Privacy**: No personal information collected