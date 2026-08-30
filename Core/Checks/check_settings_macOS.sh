#!/bin/bash
# @doc
# @name: VS Code settings status
# @description: Check whether a VS Code settings file exists on macOS
# @category: Checks
# @/doc

set -euo pipefail

settings_file="$HOME/Library/Application Support/Code/User/settings.json"
if [[ -f "$settings_file" ]]; then
    printf '%s\n' '{"schema":1,"id":"vscode-settings","status":"ready","summary":"VS Code settings are configured","installedVersion":"","latestVersion":"","details":[]}'
elif [[ ! -d "/Applications/Visual Studio Code.app" ]] && ! command -v code >/dev/null 2>&1; then
    printf '%s\n' '{"schema":1,"id":"vscode-settings","status":"blocked","summary":"Settings need VS Code","installedVersion":"","latestVersion":"","details":[]}'
else
    printf '%s\n' '{"schema":1,"id":"vscode-settings","status":"missing","summary":"VS Code settings are not configured","installedVersion":"","latestVersion":"","details":[]}'
fi
