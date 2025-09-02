# DTU macOS Installer V2

Improved, universal installer architecture that reuses existing Components while providing a clear, testable structure. This directory is self‑contained for development, while still delegating actual installs to current scripts under `MacOS/Components`.

## Goals

- Universal installer with CLI/GUI at runtime via flag or auto-detect.
- Clean phases: precheck → install → post-verify.
- Stable component interface: precheck, install, verify.
- Single code path; thin UI adapters.
- Idempotent, resumable steps with clear logs and outcomes.

## Layout

```
InstallerV2/
├── bin/
│   └── install.sh              # Universal entry (CLI/GUI via flag or auto)
├── lib/
│   ├── core.sh                 # Orchestration, phases, error handling
│   ├── config.sh               # Version pins, URLs, flags
│   ├── platform.sh             # Arch/OS detection, env checks
│   ├── logging.sh              # Logging, colors, file log
│   ├── telemetry.sh            # Analytics consent + events
│   ├── ui-cli.sh               # CLI prompts
│   └── ui-gui.sh               # GUI prompts
├── components/
│   ├── python.sh               # Wrap existing Python install
│   ├── vscode.sh               # Wrap existing VS Code install
│   └── packages.sh             # Wrap DTU packages setup
├── phases/
│   ├── pre_install.sh          # System checks → exports findings
│   └── post_install.sh         # Verification + report
├── build/
│   └── create-universal-installer.sh  # Concatenate into single file (optional)
└── README.md                   # This file
```

## Usage (dev)

```bash
# Run from repo working copy
./InstallerV2/bin/install.sh --cli   # force CLI
./InstallerV2/bin/install.sh --gui   # force GUI (requires Desktop)
./InstallerV2/bin/install.sh         # auto mode
```

## Build (single-file optional)

```bash
./InstallerV2/build/create-universal-installer.sh
# outputs: dist/dtu-installer.sh
```

## Notes

- This V2 orchestrator reuses current implementations in `MacOS/Components` to avoid duplication and ensure stability.
- Logs are written to `/tmp/dtu_install_*.log`; reports to `/tmp/dtu_installation_report_*.html` (same conventions).
- Flags: `--cli`, `--gui`, `--dry-run`, `--no-analytics`, `--prefix=PATH`.

