# macOS Next Installer – Plan

This document captures the agreed direction for a slimmer, testable macOS installer that reuses the current logic while shipping as a single built script.

## Architecture

Directory layout (minimal and modular):

```
macos-next/
  src/
    main/
      install.sh                  # single entrypoint (Phase 1)
    components/
      python/
        miniforge.sh              # install/init conda (idempotent)
        dtu_base_env.sh           # ensure Python 3.12 + DTU packages
      vscode/
        install.sh                # optional VS Code + Python extension
    utilities/
      core.sh                     # logging, args, errors, runner, precheck(), os/conda detect
      net.sh                      # download+checksum+cache (single network utility)
    etc/
      config.sh                   # versions, package list, pinned URLs + SHA256
  tools/
    build.sh                      # bundle src → dist single script (manifest-less)
    lint.sh                       # shellcheck sources + built file
  tests/
    smoke.sh                      # integration dry-run
    components/
      python.sh                   # focused checks for python pipeline
      vscode.sh                   # focused checks for vscode (optional)
    utilities/
      precheck.sh                 # focused checks for precheck() in core
  dist/
    dtu-python-installer-macos.sh
    dtu-python-installer-macos.sha256
```

UI modes:
- CLI mode: default; all confirmations and auth via TTY prompts.
- GUI mode: optional `--gui` flag triggers native dialogs via `osascript` for confirmations and admin prompts.
- UI adapter layer lives in `utilities/core.sh` under `ui::` namespace; core logic stays UI-agnostic.

Build details:
- Build script: `tools/build.sh` → `dist/dtu-python-installer-macos.sh` (+ `.sha256`).
- Deterministic, manifest-less order enforced by `tools/build.sh`.
- Inline order in builder:
  - `src/main/install.sh` (shebang retained)
  - `src/utilities/core.sh`, `src/utilities/net.sh`
  - `src/etc/config.sh`
  - `src/components/python/miniforge.sh`, `src/components/python/dtu_base_env.sh`, `src/components/vscode/install.sh`
- Modules are functions-only; builder strips other shebangs, inserts section markers, stamps version/time/checksum.
- Optional continuity: copy built script to `MacOS/releases/dtu-python-installer-macos.sh`.

## Objectives

- Modular source (main, components, utilities) with clear contracts.
- Single built installer (no runtime curls of our code).
- Idempotent and safe defaults; `--dry-run` in CI.
- Pin third‑party downloads with checksums in one place.
- Validate incrementally via component-first CI and PRs to `main`.
 - Support both CLI and GUI UX with a shared core.

## Rules/Standardizations

- Functions-only modules: importing any `src/**` file never causes side effects.
- Idempotent steps: detect → act → verify; safe to re-run.
- One download utility: all external fetches via `src/utilities/net.sh` (retry, cache, checksum, proxy-aware).
- Single source of truth for pins: `src/etc/config.sh` contains versions, URLs, SHA256.
- Safety: CI defaults to `--dry-run`; no privileged actions or shell init without `--yes`.
- Logging: single log under `/tmp/dtu_macos_next_<timestamp>.log` + concise console summary.
- Compatibility: target macOS Bash 3.2; avoid non-portable features.
- Reuse: port logic from existing `MacOS/` scripts (precheck, Miniforge, packages, VS Code) into the new structure.

### Code Conventions

- Shell baseline: `bash` 3.2, `set -euo pipefail`, and safe `IFS`.
- Namespacing: `ns::verb` function names (e.g., `precheck::run`, `python::ensure_base`).
- Local scope: prefer `local` variables inside functions; minimize globals.
- Error handling: centralized helpers in `utilities/core.sh` (`log`, `die`, `run`).
- UI abstraction: `ui::confirm`, `ui::notify`, `ui::auth_required` choose CLI vs GUI implementation at runtime.
- No ad-hoc curls: only `utilities/net.sh` may use curl; include retries and checksum.
- Idempotency: each component implements `detect`, `install`, `verify` flows.

### Documentation

- Top-level README in `macos-next/`: quickstart, layout, supported macOS versions/arch.
- Per-folder README (short): what lives here, how to extend, gotchas.
- Script headers: doc block (purpose, inputs, outputs, exit codes).
- Precheck schema: document `key=value` outputs and file location.
- ADRs: add brief records in `docs/adr/` for key choices (e.g., named env vs base).

### Tooling

- Linting: `shellcheck` across sources and built artifact; `.shellcheckrc` for minimal waivers.
- Formatting: `shfmt -i 2 -ci -sr` and `.editorconfig` for consistency.
- Pre-commit hooks: run `shellcheck` and `shfmt` on staged files.
- Task runner: `make` or `just` with targets: `lint`, `test`, `build`, `smoke`, `release`.

### Testing & CI

- Component-first CI: path-filtered jobs run only affected components/utilities.
- macOS matrix: run smoke on at least two versions (e.g., 13 and 14).
- Non-login shells: avoid `bash -l` to prevent profile side-effects.
- Assertions: tests check expected output, no writes outside `$RUNNER_TEMP`, and clear dry-run plans.
- Artifacts: upload `/tmp/dtu_macos_next_*.log` and precheck env file.
- GUI in CI: force CLI mode in CI (`--no-gui`/default). UI functions auto-downgrade to CLI when `PIS_ENV=CI` or `osascript` unavailable.

### Developer Experience

- Verbose mode: `--verbose` prints function-entry logs and commands.
- Dry-run clarity: print a step-by-step execution plan before actions.
- Onboarding: `tools/dev.sh` or `make` targets for local `lint/test/build`.
- Contribution guide: `CONTRIBUTING.md` with style, commit format, review checklist.
- GUI wrapper (later): optional tiny wrapper script that launches the built installer with `--gui` for double-click usage.

### Release & Versioning

- Versioned releases via tags; `tools/release.sh` builds dist, computes checksum, attaches assets.
- Changelog maintained in `CHANGELOG.md` (Keep a Changelog format).
- Scheduled pin updates: CI job checks new Miniforge/VS Code versions and opens PRs with updated pins and checksums.

## Implementation Plan

1) Scaffold skeleton
   - Create `macos-next/src/{main,components,utilities,etc}`, `tools/`, `tests/`, and `dist/` (git-ignored).
   - Add `src/etc/config.sh` with initial versions, URLs, and SHA256 pins.

2) CI pipeline (component-first)
   - Add `.github/workflows/macos-next.yml` with jobs: Lint → utilities/precheck test → components/python test → Build → Integration smoke.
   - Each component test runs in dry-run mode and asserts no side effects and expected output.

3) Precheck in utilities
   - Port detection logic from `MacOS/Components/Core/pre_install.sh` into `src/utilities/core.sh` as `precheck` functions.
   - Add `tests/utilities/precheck.sh` to validate schema and behaviors.

4) Python components
   - `components/python/miniforge.sh`: extract Miniforge install logic; use `utilities/net.sh` and pins from `etc/config.sh`.
   - `components/python/dtu_base_env.sh`: install/verify DTU packages; idempotent; import test.
   - Add `tests/components/python.sh` for dry-run and happy path.

5) VS Code component (optional in Phase 1)
   - Port `MacOS/Components/VSC/install.sh` → `components/vscode/install.sh` behind `--with-vscode`.
   - Add `tests/components/vscode.sh` (dry-run by default).

6) Build script
   - Implement `tools/build.sh` to inline modules in the explicit order above, add markers and checksum.
   - Output to `dist/`; upload artifacts in CI.

7) Integration smoke
   - macOS job runs `dist/dtu-python-installer-macos.sh --dry-run` (with and without `--with-vscode`).
   - Optionally add a manual “full” job (`workflow_dispatch`) with `--yes`.

8) PR and iteration
   - Open a PR to `main` from the feature branch to exercise CI, review output, and iterate.

9) GUI adapter (Phase 2)
   - Add `--gui` flag and `ui::` helpers in `utilities/core.sh` using `osascript` for dialogs and admin prompts.
   - Ensure CLI fallback when `osascript` is unavailable or in CI; add docs and minimal tests.
