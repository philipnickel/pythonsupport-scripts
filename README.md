# DTU Python Support Scripts

## Usage

### Fully offline USB bundle

**One-touch USB flash (macOS):**
Plug in your USB drive named `PISscript` and run:

```bash
bash Utils/OfflineBundle/prepare_usb.sh
```

This builds/refreshes the latest bundle and syncs it directly to the USB drive with zero manual steps.

**Build standalone release ZIP:**
```bash
uv run Utils/OfflineBundle/build_offline_bundle.py
# Or for macOS only:
uv run Utils/OfflineBundle/build_offline_bundle.py --platform macos
```

The builder packages the committed `HEAD`, so the worktree must be clean. See
[OFFLINE_BUNDLE.md](OFFLINE_BUNDLE.md) for the bundle layout, installation
instructions, and architecture support.

### MacOS

```bash
# Install (everything)
export PS_REPO_URL="https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main"; curl -fsSL "$PS_REPO_URL/Core/Orchestration/install_all_macOS.sh" | bash

```

```bash
# uninstall (everything)

export PS_REPO_URL="https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main"; curl -fsSL "$PS_REPO_URL/Core/Orchestration/uninstall_all_macOS.sh" | bash
```

### Windows

#### Install (everything)
```powershell

$env:PS_REPO_URL = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main"; irm "$env:PS_REPO_URL/Core/Orchestration/install_all_windows.ps1" | iex
```

#### uninstall (everything)

```powershell

$env:PS_REPO_URL = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main"; irm "$env:PS_REPO_URL/Core/Orchestration/uninstall_all_windows.ps1" | iex
```

# Dev 

### MacOS

```bash
# Install (everything)
export PS_REPO_URL="https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev"; curl -fsSL "$PS_REPO_URL/Core/Orchestration/install_all_macOS.sh" | bash

```

```bash
# uninstall (everything)

export PS_REPO_URL="https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev"; curl -fsSL "$PS_REPO_URL/Core/Orchestration/uninstall_all_macOS.sh" | bash
```

### Windows

#### Install (everything)
```powershell

$env:PS_REPO_URL = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev"; irm "$env:PS_REPO_URL/Core/Orchestration/install_all_windows.ps1" | iex
```

#### uninstall (everything)

```powershell

$env:PS_REPO_URL = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev"; irm "$env:PS_REPO_URL/Core/Orchestration/uninstall_all_windows.ps1" | iex
```





## Local development

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
