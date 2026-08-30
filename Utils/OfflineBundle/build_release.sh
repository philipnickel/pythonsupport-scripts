#!/bin/bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cache_root="$repo_root/release_assets/offline-cache"
refresh=0

usage() {
    cat <<'EOF'
Usage: bash Utils/OfflineBundle/build_release.sh [--refresh] [--cache-dir PATH]

Builds both release images in the repository root:
  DTU Python Support.dmg
  DTU Python Support Windows.iso

Core installers are cached locally. VS Code extensions are downloaded by the
installed VS Code CLI when setup runs and are not included in either image.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --refresh)
            refresh=1
            shift
            ;;
        --cache-dir)
            [[ $# -ge 2 ]] || { echo "--cache-dir requires a path" >&2; exit 2; }
            cache_root="$2"
            [[ "$cache_root" == /* ]] || cache_root="$repo_root/$cache_root"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

for tool in gh curl shasum go lipo hdiutil; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "Missing required build tool: $tool" >&2
        exit 1
    }
done

copy_file() {
    local source="$1"
    local destination="$2"
    mkdir -p "$(dirname "$destination")"
    cp -c "$source" "$destination" 2>/dev/null || cp "$source" "$destination"
}

verify_sha256() {
    local file="$1"
    local expected="$2"
    local actual
    actual="$(shasum -a 256 "$file" | awk '{print $1}')"
    actual="$(printf '%s' "$actual" | tr '[:upper:]' '[:lower:]')"
    expected="$(printf '%s' "$expected" | tr '[:upper:]' '[:lower:]')"
    if [[ "$actual" != "$expected" ]]; then
        echo "Checksum mismatch for $file" >&2
        echo "Expected: $expected" >&2
        echo "Actual:   $actual" >&2
        exit 1
    fi
}

echo "Reading the latest DTU Miniforge release..."
release_tag="$(gh release view --repo dtudk/pythonsupport-forge --json tagName --jq .tagName)"
asset_names="$(gh release view --repo dtudk/pythonsupport-forge --json assets --jq '.assets[].name')"

find_release_asset() {
    local suffix="$1"
    local asset
    asset="$(printf '%s\n' "$asset_names" | grep -E "^Miniforge3-[0-9][0-9.]*-[0-9]+-${suffix}$" | head -n 1)"
    [[ -n "$asset" ]] || {
        echo "Latest DTU release $release_tag has no Miniforge asset for $suffix" >&2
        exit 1
    }
    printf '%s\n' "$asset"
}

mac_arm_name="$(find_release_asset 'MacOSX-arm64\.sh')"
mac_intel_name="$(find_release_asset 'MacOSX-x86_64\.sh')"
windows_name="$(find_release_asset 'Windows-x86_64\.exe')"
miniforge_version="$(printf '%s\n' "$mac_arm_name" | sed -E 's/^Miniforge3-([0-9][0-9.]*-[0-9]+)-MacOSX-arm64\.sh$/\1/')"
miniforge_cache="$cache_root/miniforge/$release_tag"
mkdir -p "$miniforge_cache"

download_miniforge() {
    local output_variable="$1"
    local asset_name="$2"
    local destination="$miniforge_cache/$asset_name"
    local checksum_file="$destination.sha256"
    if (( refresh )) || [[ ! -f "$destination" || ! -f "$checksum_file" ]]; then
        echo "Downloading $asset_name..."
        gh release download "$release_tag" \
            --repo dtudk/pythonsupport-forge \
            --pattern "$asset_name" \
            --pattern "$asset_name.sha256" \
            --dir "$miniforge_cache" \
            --clobber
    else
        echo "Using cached $asset_name"
    fi
    local expected
    expected="$(awk 'NF {print $1; exit}' "$checksum_file")"
    [[ "$expected" =~ ^[0-9a-fA-F]{64}$ ]] || {
        echo "Invalid checksum file: $checksum_file" >&2
        exit 1
    }
    verify_sha256 "$destination" "$expected"
    printf -v "$output_variable" '%s' "$destination"
}

download_miniforge miniforge_mac_arm "$mac_arm_name"
download_miniforge miniforge_mac_intel "$mac_intel_name"
download_miniforge miniforge_windows "$windows_name"

vscode_headers() {
    curl -fsSIL "$1"
}

download_vscode() {
    local output_variable="$1"
    local platform="$2"
    local url="$3"
    local filename="$4"
    local headers expected commit destination part legacy
    headers="$(vscode_headers "$url")"
    expected="$(printf '%s\n' "$headers" | awk 'tolower($1) == "x-sha256:" {gsub("\\r", "", $2); print $2; exit}')"
    commit="$(printf '%s\n' "$headers" | awk 'tolower($1) == "x-source-commit:" {gsub("\\r", "", $2); print $2; exit}')"
    [[ "$expected" =~ ^[0-9a-fA-F]{64}$ ]] || {
        echo "VS Code did not publish a valid SHA-256 header for $platform" >&2
        exit 1
    }
    [[ "$commit" =~ ^[0-9a-fA-F]{40}$ ]] || {
        echo "VS Code did not publish a valid source commit for $platform" >&2
        exit 1
    }
    destination="$cache_root/vscode/$commit/$platform/$filename"
    legacy="$cache_root/vscode/$platform/$filename"
    mkdir -p "$(dirname "$destination")"
    if (( ! refresh )) && [[ ! -f "$destination" && -f "$legacy" ]]; then
        if [[ "$(shasum -a 256 "$legacy" | awk '{print $1}')" == "$expected" ]]; then
            mv "$legacy" "$destination"
        fi
    fi
    if (( refresh )) || [[ ! -f "$destination" ]]; then
        echo "Downloading VS Code for $platform..."
        part="$destination.part"
        rm -f "$part"
        curl -fL --retry 3 "$url" -o "$part"
        verify_sha256 "$part" "$expected"
        mv "$part" "$destination"
    else
        echo "Using cached VS Code for $platform"
    fi
    verify_sha256 "$destination" "$expected"
    printf -v "$output_variable" '%s' "$destination"
}

download_vscode vscode_macos macos-universal \
    "https://update.code.visualstudio.com/latest/darwin-universal/stable" "VSCode.zip"
download_vscode vscode_windows_x64 windows-x64 \
    "https://update.code.visualstudio.com/latest/win32-x64-user/stable" "VSCode.exe"
download_vscode vscode_windows_arm64 windows-arm64 \
    "https://update.code.visualstudio.com/latest/win32-arm64-user/stable" "VSCode.exe"

staging_root="$(mktemp -d "${TMPDIR:-/private/tmp}/dtu-python-support.XXXXXX")"
trap 'rm -rf "$staging_root"' EXIT
binary_root="$staging_root/bin"
mkdir -p "$binary_root"

go_cache="$staging_root/go-build"
go_modules="$cache_root/go-modules"
mkdir -p "$go_cache" "$go_modules"
link_flags="-s -w -X main.bundleRelease=$release_tag -X main.bundledMiniforgeVersion=$miniforge_version"

build_go() {
    local goos="$1"
    local goarch="$2"
    local output="$3"
    echo "Building Go launcher for $goos/$goarch..."
    (
        cd "$repo_root/go-launcher"
        CGO_ENABLED=0 GOOS="$goos" GOARCH="$goarch" \
            GOCACHE="$go_cache" GOMODCACHE="$go_modules" \
            go build -trimpath -ldflags "$link_flags" -o "$output" .
    )
}

build_go darwin arm64 "$binary_root/pis-launcher-darwin-arm64"
build_go darwin amd64 "$binary_root/pis-launcher-darwin-amd64"
build_go windows arm64 "$binary_root/pis-launcher-windows-arm64.exe"
build_go windows amd64 "$binary_root/pis-launcher-windows-amd64.exe"
lipo -create \
    "$binary_root/pis-launcher-darwin-arm64" \
    "$binary_root/pis-launcher-darwin-amd64" \
    -output "$binary_root/pis-launcher-macos-universal"

stage_runtime() {
    local root="$1"
    local platform="$2"
    local files=()
    if [[ "$platform" == "macos" ]]; then
        files=(
            Core/env.sh
            Core/Launcher/run_macOS.sh
            Core/Checks/check_miniforge_macOS.sh
            Core/Checks/check_vscode_macOS.sh
            Core/Checks/check_extensions_macOS.sh
            Core/Checks/check_settings_macOS.sh
            Core/Conda/install/install_macOS.sh
            Core/VsCode/install/install_macOS.sh
            Core/VsCode/config/settings_macOS.sh
            Core/VsCode/config/extensions_macOS.sh
            Core/VsCode/config/default_settings_MacOS.json
            Core/VsCode/config/extensions.txt
            Utils/Conda/uninstall_macOS.sh
            Utils/VsCode/uninstall_macOS.sh
        )
    else
        files=(
            Core/env.ps1
            Core/Launcher/run_windows.ps1
            Core/Checks/check_miniforge_windows.ps1
            Core/Checks/check_vscode_windows.ps1
            Core/Checks/check_extensions_windows.ps1
            Core/Checks/check_settings_windows.ps1
            Core/Conda/install/install_windows.ps1
            Core/VsCode/install/install_windows.ps1
            Core/VsCode/config/settings_windows.ps1
            Core/VsCode/config/extensions_windows.ps1
            Core/VsCode/config/default_settings_Windows.json
            Core/VsCode/config/extensions.txt
            Utils/Conda/uninstall_Windows.ps1
            Utils/VsCode/uninstall_Windows.ps1
        )
    fi
    local relative
    for relative in "${files[@]}"; do
        [[ -f "$repo_root/$relative" ]] || {
            echo "Missing runtime file: $relative" >&2
            exit 1
        }
        copy_file "$repo_root/$relative" "$root/$relative"
    done
}

mac_volume="$staging_root/macos-volume"
mac_resources="$mac_volume/.dtu-python-support"
mkdir -p "$mac_resources"
stage_runtime "$mac_resources" macos
copy_file "$repo_root/Utils/OfflineBundle/macos/DTU Python Support.command" \
    "$mac_volume/DTU Python Support.command"
copy_file "$binary_root/pis-launcher-macos-universal" "$mac_resources/pis-launcher"
copy_file "$miniforge_mac_arm" "$mac_resources/bundle_assets/miniforge/macos-arm64/Miniforge3.sh"
copy_file "$miniforge_mac_intel" "$mac_resources/bundle_assets/miniforge/macos-x86_64/Miniforge3.sh"
copy_file "$vscode_macos" "$mac_resources/bundle_assets/vscode/macos-universal/VSCode.zip"
chmod +x "$mac_volume/DTU Python Support.command" "$mac_resources/pis-launcher"

windows_volume="$staging_root/windows-volume"
windows_resources="$windows_volume/.dtu-python-support"
mkdir -p "$windows_resources"
stage_runtime "$windows_resources" windows
copy_file "$repo_root/Utils/OfflineBundle/windows/DTU Python Support.cmd" \
    "$windows_volume/DTU Python Support.cmd"
copy_file "$binary_root/pis-launcher-windows-amd64.exe" "$windows_resources/pis-launcher-windows-amd64.exe"
copy_file "$binary_root/pis-launcher-windows-arm64.exe" "$windows_resources/pis-launcher-windows-arm64.exe"
copy_file "$miniforge_windows" "$windows_resources/bundle_assets/miniforge/windows-x64/Miniforge3.exe"
copy_file "$vscode_windows_x64" "$windows_resources/bundle_assets/vscode/windows-x64/VSCode.exe"
copy_file "$vscode_windows_arm64" "$windows_resources/bundle_assets/vscode/windows-arm64/VSCode.exe"

dmg_output="$repo_root/DTU Python Support.dmg"
iso_output="$repo_root/DTU Python Support Windows.iso"
dmg_temp="$staging_root/DTU Python Support.dmg"
iso_temp="$staging_root/DTU Python Support Windows.iso"

echo "Creating universal macOS disk image..."
hdiutil create -quiet -volname "DTU Python Support" -srcfolder "$mac_volume" \
    -format UDZO -ov "$dmg_temp"
hdiutil verify "$dmg_temp" >/dev/null

echo "Creating universal Windows disk image..."
hdiutil makehybrid -quiet -iso -joliet -udf \
    -default-volume-name "DTU Python Support" \
    -o "$iso_temp" "$windows_volume"
iso_attach="$(hdiutil attach -readonly -nomount "$iso_temp")"
iso_device="$(printf '%s\n' "$iso_attach" | awk 'NR == 1 {print $1}')"
[[ -n "$iso_device" ]] || {
    echo "Could not mount the generated Windows ISO" >&2
    exit 1
}
hdiutil detach "$iso_device" >/dev/null

mv -f "$dmg_temp" "$dmg_output"
mv -f "$iso_temp" "$iso_output"

echo ""
echo "Created:"
du -h "$dmg_output" "$iso_output"
