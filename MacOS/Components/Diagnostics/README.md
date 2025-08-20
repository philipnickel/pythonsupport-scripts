# DTU Python Diagnostics

Comprehensive diagnostic system for DTU Python development environment setup.

## Quick Start

Run the diagnostic report with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/Components/Diagnostics/generate_report.sh | bash
```

This will:
- Download and run all diagnostic components from the repository
- Execute 12 diagnostic tests covering Python, Conda, VS Code, and system compatibility
- Generate an interactive HTML report with detailed logs
- Open the report in your default browser
- Show a summary of results in the terminal (passed/failed/timeout counts)

### Run options (one-liners)

- Default (opens report on Desktop):
```bash
curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/Components/Diagnostics/generate_report.sh | bash
```

- Save to a specific path and avoid opening a browser (use non-HTML extension):
```bash
curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/Components/Diagnostics/generate_report.sh | bash -s -- "/tmp/DTU_Diagnostics_$(date +%s).txt"
```

- Override repository coordinates at runtime (e.g., test another branch):
```bash
curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/Components/Diagnostics/generate_report.sh | REPO_BRANCH=macos-components bash
```

Notes:
- By default, the script fetches components from the `main` branch. If a file is missing there, it automatically falls back to `macos-components`.
- You can override `REPO_OWNER`, `REPO_NAME`, and `REPO_BRANCH` via environment variables as shown above.

## What it checks

- **Python Environment**: Installation, configuration, and packages
- **Conda**: Installation, environments, and configuration
- **Development Tools**: Homebrew, LaTeX, and related tools
- **VS Code**: Installation and Python development extensions
- **System Compatibility**: macOS version and development tools

## How it works

The diagnostic system features:
- **Remote execution**: Downloads all diagnostic scripts from GitHub repository
- **Modular architecture**: 12 focused diagnostic components organized by category  
- **Parallel execution**: Runs up to 5 diagnostics concurrently for speed
- **Timeout handling**: 20-second default timeout per diagnostic with proper status reporting
- **Configuration**: Uses `report_config.sh` for global settings (timeout, repository branch, parallel settings)

## Manual Installation

If you prefer to run locally:

```bash
# Clone or download the diagnostics
git clone https://github.com/philipnickel/pythonsupport-scripts.git
cd pythonsupport-scripts/MacOS/Components/Diagnostics

# Run the diagnostic
bash generate_report.sh
```

## Output

The diagnostic generates:
- Interactive HTML report with detailed logs
- Terminal summary with pass/fail/timeout counts
- Expandable sections for detailed troubleshooting
- Download and email support options in the report

## Support

For issues or questions about Python development setup at DTU, contact pythonsupport@dtu.dk