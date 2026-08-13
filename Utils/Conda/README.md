# Conda utilities

## Uninstall Conda distributions (Windows)

`uninstall_Windows.ps1` removes detected Conda plus common Miniforge, Miniconda,
Anaconda, and Mambaforge installations for the current user and the machine. It
also removes the current user's `.condarc` and `.conda` data. Machine-wide
installations may require running PowerShell as Administrator.

```powershell
irm https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev/Utils/Conda/uninstall_Windows.ps1 | iex
```
