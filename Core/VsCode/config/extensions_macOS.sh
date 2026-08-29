#!/bin/bash
# @doc
# @name: VS Code Extensions (macOS)
# @description: Install VS Code extensions from extensions.txt
# @category: Core
# @usage: bash Core/VsCode/config/extensions_macOS.sh
# @requirements: macOS, VS Code installed
# @notes: Reads extension IDs from extensions.txt (one per line, # comments and blank lines skipped)
# @/doc

set -euo pipefail

std_code_cli="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

echo "=== Installing VS Code Extensions ==="
echo ""

if [ ! -x "$std_code_cli" ]; then
    code_cli=$(command -v code 2>/dev/null || true)

    if [ ! -x "$code_cli" ]; then
        echo "  ERROR: VS Code not found at $std_code_cli"
        exit 1
    fi
else
    code_cli="$std_code_cli"
fi

failed_extensions=()
if [[ "${PS_OFFLINE:-0}" == "1" ]]; then
    if [[ -z "${PS_BUNDLE_PLATFORM:-}" ]]; then
        case "$(uname -m)" in
            arm64) export PS_BUNDLE_PLATFORM="macos-arm64" ;;
            x86_64) export PS_BUNDLE_PLATFORM="macos-x86_64" ;;
            *) echo "Unsupported macOS architecture: $(uname -m)" >&2; exit 1 ;;
        esac
    fi
    case "${PS_BUNDLE_PLATFORM:-}" in
        macos-arm64) extension_platform="darwin-arm64" ;;
        macos-x86_64) extension_platform="darwin-x64" ;;
        *) echo "Invalid or missing PS_BUNDLE_PLATFORM: ${PS_BUNDLE_PLATFORM:-}" >&2; exit 1 ;;
    esac
    extension_index="${PS_BUNDLE_ROOT:?PS_BUNDLE_ROOT is required in offline mode}/bundle_assets/extensions/$extension_platform/index.txt"
    [[ -f "$extension_index" ]] || {
        echo "Missing offline extension index: $extension_index" >&2
        exit 1
    }
    extension_arguments=()
    while IFS= read -r relative_path || [[ -n "$relative_path" ]]; do
        [[ -z "$relative_path" || "$relative_path" == \#* ]] && continue
        vsix_path="$PS_BUNDLE_ROOT/$relative_path"
        [[ -f "$vsix_path" ]] || {
            echo "Missing offline VSIX: $relative_path" >&2
            exit 1
        }
        extension_arguments+=(--install-extension "$vsix_path")
    done < "$extension_index"
    if (( ${#extension_arguments[@]} == 0 )); then
        echo "Offline extension index is empty: $extension_index" >&2
        exit 1
    fi
    if "$code_cli" "${extension_arguments[@]}" --force; then
        echo "  [OK] Bundled extensions installed"
    else
        echo "  [FAIL] Bundled extension installation" >&2
        exit 1
    fi
else
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        if "$code_cli" --install-extension "$line" --force 2>/dev/null; then
            echo "  [OK] $line"
        else
            echo "  [FAIL] $line"
            failed_extensions+=("$line")
        fi
    done < <(curl -fsSL "$PS_REPO_URL/Core/VsCode/config/extensions.txt")
fi

if (( ${#failed_extensions[@]} > 0 )); then
    echo "Failed to install extension(s): ${failed_extensions[*]}" >&2
    exit 1
fi

echo ""
echo "=== Extensions complete! ==="
