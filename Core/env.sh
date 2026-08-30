#!/bin/bash
# Shared environment configuration for DTU Python Support on macOS.

if [[ -n "${PS_OFFLINE+x}" ]]; then
    echo "PS_OFFLINE is no longer supported; use PS_ENV=offline." >&2
    return 2 2>/dev/null || exit 2
fi

if [[ "${PS_ENV_INITIALIZED:-0}" != "1" ]]; then
    default_repo_user="dtudk"
    default_branch="main"
    default_repo_url="https://raw.githubusercontent.com/$default_repo_user/pythonsupport-scripts/$default_branch"
    default_forge_url="https://github.com/dtudk/pythonsupport-forge/releases/latest/download"

    repo_url_supplied=0
    repo_user_supplied=0
    branch_supplied=0
    forge_url_supplied=0
    vscode_url_supplied=0
    bundle_root_supplied=0
    [[ -n "${PS_REPO_URL:-}" ]] && repo_url_supplied=1
    [[ -n "${PS_REPO_USER:-}" ]] && repo_user_supplied=1
    [[ -n "${PS_BRANCH:-}" ]] && branch_supplied=1
    [[ -n "${PS_FORGE_URL:-}" ]] && forge_url_supplied=1
    [[ -n "${PS_VSCODE_URL:-}" ]] && vscode_url_supplied=1
    [[ -n "${PS_BUNDLE_ROOT:-}" ]] && bundle_root_supplied=1

    case "$(uname -m)" in
        arm64)
            PS_ARCH="arm64"
            PS_BUNDLE_PLATFORM="macos-arm64"
            PS_EXTENSION_PLATFORM="darwin-arm64"
            ;;
        x86_64)
            PS_ARCH="x86_64"
            PS_BUNDLE_PLATFORM="macos-x86_64"
            PS_EXTENSION_PLATFORM="darwin-x64"
            ;;
        *)
            echo "Unsupported macOS architecture: $(uname -m)" >&2
            return 2 2>/dev/null || exit 2
            ;;
    esac

    if [[ -n "${PS_ENV:-}" ]]; then
        case "$PS_ENV" in
            main|offline|custom) ;;
            *)
                echo "Invalid PS_ENV '$PS_ENV'; expected main, offline, or custom." >&2
                return 2 2>/dev/null || exit 2
                ;;
        esac
    elif (( bundle_root_supplied )); then
        PS_ENV="offline"
    elif (( repo_url_supplied || repo_user_supplied || branch_supplied || forge_url_supplied || vscode_url_supplied )); then
        PS_ENV="custom"
    else
        PS_ENV="main"
    fi

    case "$PS_ENV" in
        main)
            if (( bundle_root_supplied || repo_url_supplied || repo_user_supplied || branch_supplied || forge_url_supplied || vscode_url_supplied )); then
                echo "PS_ENV=main cannot be combined with repository, asset, or bundle overrides." >&2
                return 2 2>/dev/null || exit 2
            fi
            PS_REPO_USER="$default_repo_user"
            PS_BRANCH="$default_branch"
            PS_REPO_URL="$default_repo_url"
            PS_FORGE_URL="$default_forge_url"
            PS_VSCODE_URL="https://update.code.visualstudio.com/latest/darwin-universal/stable"
            PS_BUNDLE_ROOT=""
            ;;
        custom)
            if (( bundle_root_supplied )); then
                echo "PS_ENV=custom cannot be combined with PS_BUNDLE_ROOT." >&2
                return 2 2>/dev/null || exit 2
            fi
            if (( ! repo_url_supplied && ! repo_user_supplied && ! branch_supplied && ! forge_url_supplied && ! vscode_url_supplied )); then
                echo "PS_ENV=custom requires a repository or asset-source override." >&2
                return 2 2>/dev/null || exit 2
            fi
            if (( repo_url_supplied && (repo_user_supplied || branch_supplied) )); then
                echo "PS_REPO_URL cannot be combined with PS_REPO_USER or PS_BRANCH." >&2
                return 2 2>/dev/null || exit 2
            fi
            if (( ! repo_url_supplied )); then
                PS_REPO_USER="${PS_REPO_USER:-$default_repo_user}"
                PS_BRANCH="${PS_BRANCH:-$default_branch}"
                PS_REPO_URL="https://raw.githubusercontent.com/$PS_REPO_USER/pythonsupport-scripts/$PS_BRANCH"
            else
                PS_REPO_URL="${PS_REPO_URL%/}"
            fi
            PS_FORGE_URL="${PS_FORGE_URL:-$default_forge_url}"
            PS_VSCODE_URL="${PS_VSCODE_URL:-https://update.code.visualstudio.com/latest/darwin-universal/stable}"
            PS_BUNDLE_ROOT=""
            ;;
        offline)
            if (( repo_url_supplied || repo_user_supplied || branch_supplied || forge_url_supplied || vscode_url_supplied )); then
                echo "PS_ENV=offline cannot be combined with online repository or asset overrides." >&2
                return 2 2>/dev/null || exit 2
            fi
            if [[ -z "${PS_BUNDLE_ROOT:-}" ]]; then
                echo "PS_BUNDLE_ROOT is required when PS_ENV=offline." >&2
                return 2 2>/dev/null || exit 2
            fi
            PS_REPO_URL="$PS_BUNDLE_ROOT"
            PS_FORGE_URL=""
            PS_VSCODE_URL=""
            ;;
    esac

    PS_ENV_INITIALIZED=1
    export PS_ENV PS_REPO_USER PS_BRANCH PS_REPO_URL PS_FORGE_URL PS_VSCODE_URL
    export PS_BUNDLE_ROOT PS_ARCH PS_BUNDLE_PLATFORM PS_EXTENSION_PLATFORM
    export PS_ENV_INITIALIZED
fi

run_repo_script() {
    local relative_path="${1:-}"
    if [[ -z "$relative_path" || "$relative_path" == /* || "$relative_path" == ".." || "$relative_path" == ../* || "$relative_path" == */../* || "$relative_path" == */.. ]]; then
        echo "Repository script path must be a safe relative path: $relative_path" >&2
        return 2
    fi

    if [[ "$PS_ENV" == "offline" ]]; then
        local script_path="$PS_BUNDLE_ROOT/$relative_path"
        [[ -f "$script_path" ]] || {
            echo "Missing offline script: $script_path" >&2
            return 1
        }
        /bin/bash "$script_path"
        return
    fi

    local temp_script
    temp_script="$(mktemp)"
    if ! curl -fsSL "$PS_REPO_URL/$relative_path" -o "$temp_script"; then
        rm -f "$temp_script"
        return 1
    fi
    /bin/bash "$temp_script"
    local status=$?
    rm -f "$temp_script"
    return "$status"
}
