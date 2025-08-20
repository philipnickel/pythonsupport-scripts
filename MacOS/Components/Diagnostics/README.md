# DTU Python Diagnostics

Comprehensive diagnostic system for DTU Python development environment setup.

## Quick Start

Run the diagnostic report with a single command:

```bash
curl -s https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/macos-components/MacOS/Components/Diagnostics/generate_report.sh | bash
```

This will:
- Auto-discover and run all diagnostic tests
- Generate an interactive HTML report
- Open the report in your default browser
- Show a summary of results in the terminal

## What it checks

- **Python Environment**: Installation, configuration, and packages
- **Conda**: Installation, environments, and configuration
- **Development Tools**: Homebrew, LaTeX, and related tools
- **VS Code**: Installation and Python development extensions
- **System Compatibility**: macOS version and development tools

## Configuration

The diagnostic system uses `report_config.sh` for global settings:
- Default timeout values
- Repository settings for manual commands
- Parallel execution settings
- Display preferences

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