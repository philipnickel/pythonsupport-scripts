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
```powershell
# Install (Windows)
irm https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev/Core/Orchestration/install_all_windows.ps1 | iex
```


## Local development

### Windows

Windows installer logic is tested with PowerShell in Docker. Docker Desktop
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

