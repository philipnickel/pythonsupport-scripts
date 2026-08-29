#!/bin/bash
# @doc
# @name: Prepare USB Drive (macOS)
# @description: Builds the latest offline bundle and flashes it onto a USB drive named PISscript
# @category: OfflineBundle
# @usage: bash Utils/OfflineBundle/prepare_usb.sh [--platform macos|all|windows] [--format]
# @requirements: macOS, USB flash drive
# @/doc

set -euo pipefail

VOLUME_NAME="PISscript"
DEST_VOLUME="/Volumes/$VOLUME_NAME"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

PLATFORM="macos"
DO_FORMAT=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --platform|-p)
            PLATFORM="$2"
            shift 2
            ;;
        --format|-f)
            DO_FORMAT=1
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--platform macos|all|windows] [--format]"
            echo "  --platform, -p  Target platform (default: macos)"
            echo "  --format, -f    Force format the USB drive even if already mounted"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

echo "====================================================="
echo "       DTU Python Support - USB Flash Assistant"
echo "====================================================="
echo "Target Platform: $PLATFORM"
echo "Target Volume:   $DEST_VOLUME"
echo "====================================================="
echo ""

# 1. Build the offline bundle
echo ">>> [1/4] Building offline bundle..."
(cd "$REPO_ROOT" && uv run Utils/OfflineBundle/build_offline_bundle.py --platform "$PLATFORM")

# Find the latest generated ZIP in dist/
latest_zip="$(ls -t "$REPO_ROOT/dist"/DTU-Python-Support-Offline-*.zip 2>/dev/null | head -n 1)"
if [[ -z "$latest_zip" ]]; then
    echo "Error: No bundle ZIP found in dist/!" >&2
    exit 1
fi
echo "[OK] Built bundle: $(basename "$latest_zip")"
echo ""

# 2. Check USB mount or format
echo ">>> [2/4] Checking USB drive..."
if [[ "$DO_FORMAT" == "1" && -d "$DEST_VOLUME" ]]; then
    echo "Forced format requested. Looking up disk for $DEST_VOLUME..."
    disk_id="$(diskutil info "$DEST_VOLUME" | awk -F': *' '/Part of Whole/ {print $2}')"
    if [[ -z "$disk_id" ]]; then
        echo "Error: Could not identify disk for $DEST_VOLUME" >&2
        exit 1
    fi
    echo "Erasing /dev/$disk_id as ExFAT '$VOLUME_NAME'..."
    diskutil eraseDisk ExFAT "$VOLUME_NAME" MBR "/dev/$disk_id"
fi

if [[ ! -d "$DEST_VOLUME" ]]; then
    echo "USB drive '$VOLUME_NAME' is not currently mounted."
    echo ""
    echo "Available external drives:"
    diskutil list external
    echo ""
    read -r -p "Enter target disk to format as '$VOLUME_NAME' (e.g. disk4): " target_disk
    if [[ -z "$target_disk" ]]; then
        echo "Aborted." >&2
        exit 1
    fi
    echo "Erasing /dev/$target_disk as ExFAT '$VOLUME_NAME'..."
    diskutil eraseDisk ExFAT "$VOLUME_NAME" MBR "/dev/$target_disk"
fi

if [[ ! -d "$DEST_VOLUME" ]]; then
    echo "Error: $DEST_VOLUME is not mounted after formatting." >&2
    exit 1
fi
echo "[OK] USB drive ready at: $DEST_VOLUME"
echo ""

# 3. Unpack and sync to USB
echo ">>> [3/4] Copying offline bundle to $DEST_VOLUME..."
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

unzip -q "$latest_zip" -d "$tmp_dir"
bundle_folder="$(ls "$tmp_dir")"

echo "Syncing files to USB..."
rsync -rtv --progress \
    --exclude=".*" \
    --exclude="._*" \
    "$tmp_dir/$bundle_folder/" "$DEST_VOLUME/"
echo ""

# 4. Finalize permissions and flush disk cache
echo ">>> [4/4] Finalizing USB drive..."
chmod +x "$DEST_VOLUME/Install macOS.command" 2>/dev/null || true
echo "Flushing disk cache (syncing)..."
sync

echo ""
echo "====================================================="
echo " [OK] USB drive '$VOLUME_NAME' is prepared and ready!"
echo " Safe to unplug or test directly from: $DEST_VOLUME"
echo "====================================================="
