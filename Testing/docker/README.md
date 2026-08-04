# Windows script testing via Docker

Docker on macOS cannot run real Windows containers (they need a Windows
kernel). This setup instead runs **PowerShell (pwsh) on Debian**, which is
enough to test the `*_windows.ps1` scripts' syntax and logic.

The repo root is mounted at `/repo` in the container, and a tiny HTTP server
serves it at `http://127.0.0.1:8000` (`$PS_REPO_URL`), since pwsh 7's
`Invoke-WebRequest` does not support `file://` URLs.

## Usage

```bash
# Interactive pwsh shell (repo mounted at /repo)
Testing/docker/run.sh

# Run a script directly
Testing/docker/run.sh -File ./Core/VsCode/config/settings_windows.ps1

# Reset to a clean state (wipes in-container state, keeps the mount)
Testing/docker/reset.sh
```

## Limitations

- Not a real Windows: no registry, no `.exe` installers (e.g. the VS Code
  setup in `install_windows.ps1` cannot run).
- Windows-style paths (`$env:APPDATA\Code\User`) become literal filenames
  containing backslashes on Linux — functional, but not identical layout.
