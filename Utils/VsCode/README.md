# VS Code utilities

## Uninstall completely (Windows)

`uninstall_Windows.ps1` runs the per-user VS Code uninstaller and removes the
current user's `%APPDATA%\Code` and `%USERPROFILE%\.vscode` data.

Run it through the `uninstall-vscode` or `uninstall-all` command-launcher action.
Utility scripts require the shared environment to be initialized and are not
standalone remote entrypoints.
