# Windows script testing via Docker

Docker on macOS cannot run real Windows containers (they need a Windows
kernel). This setup instead runs **PowerShell (pwsh) on Debian**, which is
enough to test the `*_windows.ps1` scripts' syntax and logic.

The repo root is mounted at `/repo` in the container, and a tiny HTTP server
serves it at `http://127.0.0.1:8000` (`$PS_REPO_URL`), since pwsh 7's
`Invoke-WebRequest` does not support `file://` URLs.

## Usage

```bash
# Rebuild the image, reset the container, and run the full Windows test suite
Testing/docker/test.sh

# Interactive pwsh shell (repo mounted at /repo)
Testing/docker/run.sh

# Run a script directly
Testing/docker/run.sh -File ./Core/VsCode/config/settings_windows.ps1

# Reset to a clean state (wipes in-container state, keeps the mount)
Testing/docker/reset.sh
```

The test suite uses temporary Windows-style user directories whose names contain
spaces. It serves the real repository scripts over local HTTP, replaces only
installer process execution and the VS Code CLI, and verifies:

- PowerShell parsing for every `.ps1` file
- Conda and VS Code download selection, silent arguments, exit codes, and cleanup
- settings creation and preservation
- extension filtering, invocation, and failure propagation
- full Conda-then-VS-Code orchestration and success-banner behavior

No downloaded fixture is executed. The small `.exe` files under
`Testing/windows/fixtures/` are plain-text HTTP fixtures.

## Final Windows smoke test

After the local suite passes, run the production command once from Windows
PowerShell 5.1 on a clean Windows x64 account:

```powershell
$env:PS_REPO_URL = "https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/august"; irm "$env:PS_REPO_URL/Core/Orchestration/install_all_windows.ps1" | iex
```

Confirm that:

1. Miniforge is available from **Miniforge Prompt**.
2. VS Code launches and retains the installed Windows defaults.
3. `ms-python.python` and `ms-toolsai.jupyter` are installed.
4. The command prints the final success banner only after both installation steps finish.

The local suite validates ARM64 URL selection and the x64 Miniforge emulation
message. A real ARM64 installation is optional unless suitable hardware is
available.

## Limitations

- Not a real Windows: no registry, no `.exe` installers (e.g. the VS Code
  setup in `install_windows.ps1` cannot run).
- PowerShell 7 on Debian cannot prove Windows PowerShell 5.1 runtime behavior;
  the final Windows smoke test remains required.
