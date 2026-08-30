# DTU Python Support Scripts

The installers support three environments through the shared `PS_*`
configuration in `Core/env.sh` and `Core/env.ps1`:

- `main`: official online installation from `dtudk/pythonsupport-scripts`.
- `offline`: use adjacent bundled installers for Miniforge and VS Code. VS Code
  extensions still require Marketplace access.
- `custom`: a fork, branch, raw repository URL, or custom asset source.

The full-install scripts default to online `main`. The interactive command
launchers default to `offline` and use their own directory as the bundle root.
An unavailable Marketplace does not roll back or fail an aggregate core
installation; the launcher reports any extensions still missing afterward.

## Official online installation

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Core/Orchestration/install_all_macOS.sh | bash
```

### Windows

```powershell
irm https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Core/Orchestration/install_all_windows.ps1 | iex
```

## Custom forks and branches

`PS_REPO_USER` and `PS_BRANCH` select a fork and branch. Both variables are
exported so they reach the shell receiving the downloaded script.

### macOS

```bash
export PS_REPO_USER="philipnickel"
export PS_BRANCH="feat/my-feature"
curl -fsSL "https://raw.githubusercontent.com/$PS_REPO_USER/pythonsupport-scripts/$PS_BRANCH/Core/Orchestration/install_all_macOS.sh" | bash
```

### Windows

```powershell
$env:PS_REPO_USER = "philipnickel"
$env:PS_BRANCH = "feat/my-feature"
irm "https://raw.githubusercontent.com/$env:PS_REPO_USER/pythonsupport-scripts/$env:PS_BRANCH/Core/Orchestration/install_all_windows.ps1" | iex
```

For another raw source, set `PS_REPO_URL` instead. It cannot be combined with
`PS_REPO_USER` or `PS_BRANCH`.

```bash
export PS_REPO_URL="https://raw.githubusercontent.com/example/pythonsupport-scripts/topic"
curl -fsSL "$PS_REPO_URL/Core/Orchestration/install_all_macOS.sh" | bash
```

`PS_FORGE_URL` and `PS_VSCODE_URL` may override the online installer sources.
Any repository or asset override selects the `custom` environment when
`PS_ENV` is unset.

## Health-first Go launcher prototype

The compiled `DTU Python Support` launcher checks the local installation before
offering changes. It summarizes DTU Miniforge, VS Code, required extension IDs,
and VS Code settings. A fresh computer gets a short “Install everything” path;
otherwise it opens actions grouped under “Install things” and “Uninstall
things.”
The selected Bash or PowerShell process streams directly through the native
terminal. The launcher does not create persistent log files.

The Go launcher contains a small fixed catalog of the six supported actions and
four checks. Aggregate operations call the platform leaf scripts directly, so
they do not depend on shell functions surviving across nested processes. See
[`go-launcher/README.md`](go-launcher/README.md) for the action and check
contracts.

## Offline launchers

Build both mounted images as described in
[OFFLINE_BUNDLE.md](OFFLINE_BUNDLE.md). On macOS, double-click
`DTU Python Support.command` in the DMG. On Windows, double-click
`DTU Python Support.cmd` in the ISO. Both wrappers select `offline` mode and
keep installers adjacent to the launcher.

The menu and command line support these actions:

| Name | Numeric alias | Behavior |
| --- | ---: | --- |
| `install-all` | `1` | Install Miniforge, VS Code, settings, then try online extensions |
| `install-conda` | `2` | Install Miniforge only |
| `install-vscode` | `3` | Install VS Code and settings, then try online extensions |
| `uninstall-all` | `4` | Uninstall VS Code, then Conda |
| `uninstall-conda` | `5` | Uninstall Conda only |
| `uninstall-vscode` | `6` | Uninstall VS Code only |

Examples:

```bash
bash "Install macOS.command" install-vscode
PS_ENV=main bash "Install macOS.command" install-all
```

```powershell
.\Install Windows.ps1 -Action install-vscode
$env:PS_ENV = "main"; .\Install Windows.ps1 -Action install-all
```

Full uninstall is available through the command launcher, not as a remote
one-liner.

## Local development

Component scripts are environment-dependent leaf operations and are not
standalone entrypoints. Test the complete local checkout by selecting it as the
custom repository source and invoking full install:

```bash
export PS_REPO_URL="file://$PWD"
bash Core/Orchestration/install_all_macOS.sh
```

Open a new terminal or unset the `PS_*` variables before switching profiles.
`PS_OFFLINE` is no longer supported; use `PS_ENV=offline` with
`PS_BUNDLE_ROOT`.

## Building an offline bundle

```bash
bash Utils/OfflineBundle/build_release.sh
```

The builder writes the universal `DTU Python Support.dmg` and architecture-
selecting `DTU Python Support Windows.iso` in the repository root. Miniforge,
VS Code, scripts, and settings work offline. VSIX files are deliberately not
bundled; installing required extensions needs an internet connection.
