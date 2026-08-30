#!/bin/bash
# @doc
# @name: DTU Miniforge status
# @description: Check the installed DTU Miniforge release on macOS
# @category: Checks
# @/doc

set -euo pipefail

json_escape() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    printf '%s' "$value"
}

version_key() {
    awk -F '[.-]' 'NF >= 3 { printf "%09d.%09d.%09d.%09d", $1, $2, $3, ($4 == "" ? 0 : $4) }' <<< "$1"
}

install_dir="$HOME/miniforge3-dtu"
conda_exe="$install_dir/bin/conda"
marker="$install_dir/.dtu-python-support.json"
installed=""
installed_dtu=0
latest=""
detail=""

if [[ -f "$marker" ]]; then
    installed="$(sed -nE 's/.*"dtuRelease"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$marker" | head -n 1)"
    [[ -n "$installed" ]] && installed_dtu=1
fi
if [[ -z "$installed" && -f "$install_dir/.installer.info" ]]; then
    installed="$(sed -nE 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$install_dir/.installer.info" | head -n 1)"
    [[ -n "$installed" ]] && detail="Installer version found, but the DTU release is unknown"
fi

release_json="$(curl -fsSL --connect-timeout 2 --max-time 5 \
    "https://api.github.com/repos/dtudk/pythonsupport-forge/releases/latest" 2>/dev/null || true)"
latest="$(sed -nE 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' <<< "$release_json" | head -n 1)"

status="unknown"
summary="DTU Miniforge is not installed"
if [[ ! -x "$conda_exe" ]]; then
    status="missing"
elif [[ -z "$installed" ]]; then
    summary="DTU Miniforge is installed — version unknown"
    detail="This installation predates DTU release markers"
elif (( ! installed_dtu )); then
    summary="DTU Miniforge is installed — DTU release unknown"
elif [[ -z "$latest" ]]; then
    summary="DTU Miniforge $installed — latest version unavailable"
    detail="Could not reach the DTU release service"
else
    installed_key="$(version_key "$installed")"
    latest_key="$(version_key "$latest")"
    if [[ "$installed" == "$latest" ]]; then
        status="ready"
        summary="DTU Miniforge $installed"
    elif [[ -n "$installed_key" && -n "$latest_key" && "$installed_key" < "$latest_key" ]]; then
        status="outdated"
        summary="DTU Miniforge $installed — update $latest available"
        detail="Updates are informational and are not installed automatically"
    elif [[ -n "$installed_key" && -n "$latest_key" && "$installed_key" > "$latest_key" ]]; then
        status="ready"
        summary="DTU Miniforge $installed — ahead of public release $latest"
    else
        summary="DTU Miniforge $installed — latest is $latest"
        detail="The release tags could not be compared safely"
    fi
fi

printf '{"schema":1,"id":"miniforge","status":"%s","summary":"%s","installedVersion":"%s","latestVersion":"%s","details":[' \
    "$status" "$(json_escape "$summary")" "$(json_escape "$installed")" "$(json_escape "$latest")"
if [[ -n "$detail" ]]; then
    printf '"%s"' "$(json_escape "$detail")"
fi
printf ']}\n'
