#!/bin/bash
# @doc
# @name: VS Code extensions status
# @description: Check that every required DTU VS Code extension is installed
# @category: Checks
# @/doc

set -euo pipefail

json_escape() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '%s' "$value"
}

standard_code_cli="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
code_cli="$(command -v code 2>/dev/null || true)"
if [[ ! -x "$code_cli" && -x "$standard_code_cli" ]]; then
    code_cli="$standard_code_cli"
fi
if [[ -z "$code_cli" || ! -x "$code_cli" ]]; then
    printf '%s\n' '{"schema":1,"id":"vscode-extensions","status":"blocked","summary":"Extensions need VS Code","installedVersion":"","latestVersion":"","details":[]}'
    exit 0
fi

if [[ "${PS_ENV:-}" == "offline" ]]; then
    extensions_file="${PS_BUNDLE_ROOT:?PS_BUNDLE_ROOT is required}/Core/VsCode/config/extensions.txt"
    expected_content="$(<"$extensions_file")"
else
    expected_content="$(curl -fsSL --connect-timeout 2 --max-time 5 "${PS_REPO_URL%/}/Core/VsCode/config/extensions.txt")"
fi
installed_content="$("$code_cli" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"
missing=()
while IFS= read -r extension || [[ -n "$extension" ]]; do
    extension="${extension%%$'\r'}"
    [[ -z "$extension" || "$extension" == \#* ]] && continue
    extension_lower="$(tr '[:upper:]' '[:lower:]' <<< "$extension")"
    if ! grep -Fqx "$extension_lower" <<< "$installed_content"; then
        missing+=("$extension")
    fi
done <<< "$expected_content"

if (( ${#missing[@]} == 0 )); then
    printf '%s\n' '{"schema":1,"id":"vscode-extensions","status":"ready","summary":"All required extensions are installed","installedVersion":"","latestVersion":"","details":[]}'
    exit 0
fi

printf '{"schema":1,"id":"vscode-extensions","status":"missing","summary":"%d required extension(s) missing","installedVersion":"","latestVersion":"","details":[' "${#missing[@]}"
for index in "${!missing[@]}"; do
    (( index > 0 )) && printf ','
    printf '"%s"' "$(json_escape "${missing[$index]}")"
done
printf ']}\n'
