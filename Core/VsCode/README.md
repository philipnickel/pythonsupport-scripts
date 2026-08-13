# VS Code

## Install (macOS)

Installs VS Code, applies default settings, and installs extensions.

```bash
curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Core/VsCode/install/install_macOS.sh | bash
```

## Install (Windows)

The full Windows one-liner installs VS Code after Miniforge:

```powershell
irm https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev/Core/Orchestration/install_all_windows.ps1 | iex
```

For local integration tests, `PS_VSCODE_URL` can override the VS Code installer
download URL. Production installs leave it unset and select the x64 or ARM64
stable user installer automatically.

## Uninstall (macOS)

Removes VS Code, settings, extensions, and user data.

```bash
curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Utils/VsCode/uninstall_macOS.sh | bash
```

## Default settings

- Disable AI features
- Disable chat agent
- Set Python locator to JS
- Disable telemetry

## Extensions

Listed and commented in `config/extensions.txt`.
