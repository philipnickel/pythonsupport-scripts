# macos-next (Prototype)

A slimmer, testable macOS installer architecture that builds into a single script while keeping source modular.

## Quickstart

- Dry-run plan (no changes):
  - `bash macos-next/tools/build.sh`
  - `macos-next/dist/dtu-python-installer-macos.sh --dry-run`
- Include VS Code in the plan:
  - `macos-next/dist/dtu-python-installer-macos.sh --dry-run --with-vscode`
- Help:
  - `macos-next/dist/dtu-python-installer-macos.sh --help`

## Structure

- `src/main/install.sh` — entrypoint; prints plan, runs precheck; orchestrates steps
- `src/utilities/core.sh` — logging, args, precheck, runner, UI stubs
- `src/utilities/net.sh` — simple download helper (no checksum in prototype)
- `src/etc/config.sh` — Miniforge path, version, DTU package list, URLs
- `src/components/python/` — Miniforge install; ensure DTU base env; verify
- `src/components/vscode/` — optional VS Code install (dry-run default)
- `tools/build.sh` — bundles sources into `dist/dtu-python-installer-macos.sh`

## CI (basic)

- Component tests: precheck, python, vscode (all dry-run) on macOS
- Build on Ubuntu; smoke (dry-run) on macOS

## Notes

- Prototype intentionally omits checksum verification for speed of iteration.
- GUI mode is planned (Phase 2) via `osascript` dialogs, but CLI is default.
- Runners are ephemeral; full, non-dry-run tests can be added later as manual jobs.

