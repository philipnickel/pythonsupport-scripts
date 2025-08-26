# Diagnostics Component

Modern diagnostic system for macOS that collects environment data and produces an interactive HTML report.

## Quick Start

Run the diagnostics with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/Components/Diagnostics/generate_report.sh | bash
```

This downloads all diagnostic components, runs checks in parallel, generates a styled HTML report, opens it in your browser, and prints a summary.

## What it checks

- Python: installation, configuration, and required packages
- Conda: installation and environments
- Development tools: Homebrew and LaTeX
- VS Code: installation and Python extensions
- System: hardware/software info and Python development compatibility

## Run options

- Save output without opening a browser (use non-HTML extension):
```bash
curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/Components/Diagnostics/generate_report.sh | bash -s -- "/tmp/DTU_Diagnostics_$(date +%s).txt"
```

- Override repository coordinates at runtime (for testing branches):
```bash
curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/Components/Diagnostics/generate_report.sh | REPO_BRANCH=macos-components bash
```

Notes:
- By default, components are fetched from the `main` branch and automatically fall back to `macos-components` if needed.
- You can override `REPO_OWNER`, `REPO_NAME`, and `REPO_BRANCH` as environment variables.

## Output

- HTML report with expandable logs, summary counters, and a “Download Report” button
- Terminal summary with pass/fail/timeout counts
- Email template generator for support

## Auto-generated docs

Technical details are included in the auto-generated docs: [Diagnostics (generated)](../../generated/diagnostics.md)
