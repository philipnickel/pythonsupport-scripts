# Conda utilities

## Uninstall Conda distributions (Windows)

`uninstall_Windows.ps1` removes detected Conda plus common Miniforge, Miniconda,
Anaconda, and Mambaforge installations under `%USERPROFILE%`. It also removes
the current user's `.condarc` and `.conda` data. Machine-wide installations
outside the current user profile are skipped as a safety boundary.

```powershell
irm https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev/Utils/Conda/uninstall_Windows.ps1 | iex
```
