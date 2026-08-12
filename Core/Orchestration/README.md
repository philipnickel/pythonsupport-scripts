# Orchestration

One-command install or uninstall of the full DTU Python Support stack.

## Install everything (macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Core/Orchestration/install_all_macOS.sh | bash
```

## Uninstall everything (macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Core/Orchestration/uninstall_all_macOS.sh | bash
```

## Install everything (Windows)

```powershell
irm https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev/Core/Orchestration/install_all_windows.ps1 | iex
```

## Uninstall everything (Windows)

This removes detected per-user and machine-wide Conda distributions and
environments, current-user Conda data, VS Code, VS Code settings, and
extensions. Run PowerShell as Administrator for machine-wide installations:

```powershell
irm https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev/Core/Orchestration/uninstall_all_windows.ps1 | iex
```
