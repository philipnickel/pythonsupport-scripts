# DTU Python Support Scripts

## Usage

### MacOS

```bash
# Install (everything)
curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev/Core/Orchestration/install_all_macOS.sh | bash

```

```bash
# uninstall (everything)

curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev/Core/Orchestration/uninstall_all_macOS.sh | bash
```

### Windows

Run this one-liner in **Windows PowerShell 5.1**. It pins the complete install
to this fork's `august` branch, including every child script:

```powershell
$env:PS_REPO_URL = "https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/august"; irm "$env:PS_REPO_URL/Core/Orchestration/install_all_windows.ps1" | iex
```

This installs Miniforge first, followed by VS Code, the default settings, and
the Python and Jupyter extensions. The production installer sources are:

- [DTU Miniforge for Windows x64](https://github.com/dtudk/pythonsupport-forge/releases/latest/download/Miniforge3-Windows-x86_64.exe)
- [VS Code stable user installer for Windows x64](https://update.code.visualstudio.com/latest/win32-x64-user/stable)
- [VS Code stable user installer for Windows ARM64](https://update.code.visualstudio.com/latest/win32-arm64-user/stable)

Miniforge currently provides an x64 installer on Windows; Windows ARM64 runs it
under emulation. VS Code uses its native ARM64 installer automatically.

To remove the complete Windows installation from the current user, including
all Conda distributions and environments under `%USERPROFILE%`, Conda user
data, VS Code settings, and extensions:

```powershell
$env:PS_REPO_URL = "https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/august"; irm "$env:PS_REPO_URL/Core/Orchestration/uninstall_all_windows.ps1" | iex
```

Both fork-pinned one-liners overwrite `PS_REPO_URL` for the current PowerShell
process. The scripts themselves continue to default to the official
`dtudk/pythonsupport-scripts` `dev` branch.

## Local development

### Windows

Windows install and uninstall logic is tested with PowerShell in Docker. Docker Desktop
must be running:

```bash
Testing/docker/test.sh
```

This rebuilds the test image, resets the test container, and runs the complete
dependency-free integration suite. Real `.exe` execution is intentionally
mocked and must be smoke-tested once on Windows; see `Testing/docker/README.md`.

### macOS

To test scripts against your local checkout instead of the remote GitHub repo, point `PS_REPO_URL` at the local repo root using a `file://` URL. All internal `curl` calls will then read from disk, so uncommitted changes are tested too.

1. Open a terminal at the repo root (the directory containing this README).
2. Export the repo root as a `file://` URL:

   ```bash
   export PS_REPO_URL="file://$PWD"
   ```

   If you are in a subdirectory, use an absolute path instead:

   ```bash
   export PS_REPO_URL="file:///path/to/pythonsupport-scripts"
   ```

3. Run any script directly:

   ```bash
   bash Core/Orchestration/install_all_macOS.sh
   bash Core/VsCode/config/settings_macOS.sh
   bash Core/VsCode/config/extensions_macOS.sh
   bash Core/Orchestration/uninstall_all_macOS.sh
   ```

The variable only lives in the current shell session. Open a new terminal, or run `unset PS_REPO_URL`, to go back to testing against the remote repo.

### How it works

All scripts use `curl -fsSL "$PS_REPO_URL/..."` to reference other files in the repo.

- **Orchestration scripts** default `PS_REPO_URL` to the GitHub raw URL and export it so child scripts inherit it.
- **Child scripts** expect `PS_REPO_URL` to be set in the environment.
- For local testing, `export PS_REPO_URL="file://$PWD"` makes `curl` read from the local filesystem instead.
