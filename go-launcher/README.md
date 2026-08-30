# Go launcher prototype

`pis-launcher` is an additive, health-first terminal UI for the DTU Python
Support Bash and PowerShell scripts. Scripts and assets remain adjacent to the
binary and are not embedded.

## Interactive flow

Run the binary without arguments:

```console
./pis-launcher
```

The launcher checks DTU Miniforge, VS Code, the required extension IDs, and the
presence of VS Code settings. When neither Miniforge nor VS Code is installed,
it offers the short path to install everything or open the full overview. Every
other result opens a compact health summary followed by actions grouped under
`Install things` and `Uninstall things`.

Offline bundles contain Miniforge, VS Code, and settings locally. Required VS
Code extensions are installed by ID from the Marketplace and therefore need an
internet connection; failure leaves the core install intact for a later retry.

Nothing is installed until the selected action is confirmed. Uninstall actions
use a stronger destructive-action confirmation. Escape, Ctrl+C, or closing the
window cancels; there is no Quit menu item.

After confirmation, the menu closes and the Bash or PowerShell process streams
directly through the native terminal. This preserves script colors, child
input, and exit codes without a custom output viewport or persistent logs.
After a successful action, checks run again and a final Huh prompt offers Close
or Return to overview.

Use `--accessible` or `PIS_ACCESSIBLE=1` for plain prompts without an alternate
screen buffer.

## Named actions

Named actions skip the health wizard:

```console
./pis-launcher install-vscode
./pis-launcher --bundle-root "/path/to/offline bundle" install-all
```

The launcher has a fixed catalog of six public actions and four checks. Each
action maps to explicit platform-specific leaf scripts under `Core/` and
`Utils/`; metadata parsing and nested orchestration scripts are not involved.
A successful check prints exactly one schema-v1 JSON object and uses one of:
`ready`, `missing`, `outdated`, `unknown`, `blocked`, or `error`. Health findings
such as `missing` do not use a failing process exit code.

The current compatibility actions remain `install-all`, `install-conda`,
`install-vscode`, `uninstall-all`, `uninstall-conda`, and `uninstall-vscode`.
`install-all` and `install-vscode` execute their leaf steps directly from Go.
An extension installation failure is reported but does not undo or fail the
core installation. All other child failures propagate immediately.

## Exit codes

| Code | Meaning |
| ---: | --- |
| `0` | Completed successfully |
| `1` | Wrapper, check-display, or process-start failure |
| `2` | Invalid command line or action |
| `3` | Platform bootstrap or selected script is missing |
| `130` | Interactive flow cancelled |

A delegated action's nonzero exit code is otherwise returned unchanged.

## Develop, test, and build

The module pins `charm.land/huh/v2` v2.0.3 and requires Go 1.25.8 or newer.

```console
go test -race ./...
go vet ./...
go run . --bundle-root .. install-vscode
```

The final command performs the real selected action. Automated tests use stub
scripts and do not install or remove software.

Build the two complete release images from the repository root:

```console
bash Utils/OfflineBundle/build_release.sh
```

This cross-builds macOS and Windows arm64/amd64 binaries, combines the macOS
builds with `lipo`, and writes `DTU Python Support.dmg` and
`DTU Python Support Windows.iso` in the repository root. Builds use
`CGO_ENABLED=0` and need no Go runtime on the target computer.
