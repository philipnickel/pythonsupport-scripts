# VS Code utilities

## Uninstall completely (Windows)

`uninstall_Windows.ps1` runs the per-user VS Code uninstaller and removes the
current user's `%APPDATA%\Code` and `%USERPROFILE%\.vscode` data.

```powershell
irm https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev/Utils/VsCode/uninstall_Windows.ps1 | iex
```
