#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/../dist"
OUT="$DIST_DIR/dtu-installer.sh"

mkdir -p "$DIST_DIR"

# Simple concatenation build: create a single script that sources embedded parts.
# For now we just stitch files in a deterministic order; network downloads remain external.

{
  echo "#!/usr/bin/env bash"
  echo "set -euo pipefail"
  echo "# Generated universal installer"
  echo "EMBEDDED=1"
  echo "ROOT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")\" && pwd)\""

  echo "# --- logging ---"
  cat "$ROOT_DIR/lib/logging.sh"
  echo "# --- config ---"
  cat "$ROOT_DIR/lib/config.sh"
  echo "# --- platform ---"
  cat "$ROOT_DIR/lib/platform.sh"
  echo "# --- telemetry ---"
  cat "$ROOT_DIR/lib/telemetry.sh"
  echo "# --- ui cli ---"
  cat "$ROOT_DIR/lib/ui-cli.sh"
  echo "# --- ui gui ---"
  cat "$ROOT_DIR/lib/ui-gui.sh"

  echo "# --- phases ---"
  cat "$ROOT_DIR/phases/pre_install.sh"
  cat "$ROOT_DIR/phases/post_install.sh"

  echo "# --- components ---"
  cat "$ROOT_DIR/components/python.sh"
  cat "$ROOT_DIR/components/vscode.sh"
  cat "$ROOT_DIR/components/packages.sh"

  echo "# --- core ---"
  cat "$ROOT_DIR/lib/core.sh"
  echo 'main_core "$@"'
} > "$OUT"

chmod +x "$OUT"
echo "Built: $OUT"

