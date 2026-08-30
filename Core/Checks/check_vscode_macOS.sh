#!/bin/bash
# @doc
# @name: VS Code status
# @description: Check whether VS Code is installed on macOS
# @category: Checks
# @/doc

set -euo pipefail

app_path="/Applications/Visual Studio Code.app"
code_cli="$app_path/Contents/Resources/app/bin/code"
version=""
if [[ -d "$app_path" ]]; then
    version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_path/Contents/Info.plist" 2>/dev/null || true)"
fi
if [[ -z "$version" ]]; then
    candidate="$(command -v code 2>/dev/null || true)"
    if [[ -n "$candidate" ]]; then
        code_cli="$candidate"
        version="$("$code_cli" --version 2>/dev/null | head -n 1 || true)"
    fi
fi

if [[ -d "$app_path" || -x "$code_cli" ]]; then
    summary="VS Code is installed"
    [[ -n "$version" ]] && summary="VS Code $version"
    printf '{"schema":1,"id":"vscode","status":"ready","summary":"%s","installedVersion":"%s","latestVersion":"","details":[]}\n' "$summary" "$version"
else
    printf '%s\n' '{"schema":1,"id":"vscode","status":"missing","summary":"VS Code is not installed","installedVersion":"","latestVersion":"","details":[]}'
fi
