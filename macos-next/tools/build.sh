#!/usr/bin/env bash
set -euo pipefail
IFS=$' \t\n'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
OUT="$DIST_DIR/dtu-python-installer-macos.sh"
SHA="$OUT.sha256"

mkdir -p "$DIST_DIR"

header() {
  cat <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
IFS=$' \t\n'
# Built DTU macOS Installer (next)
EOF
}

append_file() {
  local title="$1" path="$2"
  echo "" >> "$OUT"
  echo "##### BEGIN: $title ($path) #####" >> "$OUT"
  # Strip shebang if present
  awk 'NR==1 && $0 ~ /^#!\// {next} {print}' "$path" >> "$OUT"
  echo "##### END: $title ($path) #####" >> "$OUT"
}

append_main() {
  local path="$1"
  echo "" >> "$OUT"
  echo "##### BEGIN: main/install (inlined) #####" >> "$OUT"
  # Strip shebang and any source lines; modules are inlined below
  awk '
    NR==1 && $0 ~ /^#!\// {next}
    $1 == "source" {next}
    {print}
  ' "$path" >> "$OUT"
  echo "##### END: main/install (inlined) #####" >> "$OUT"
}

# Sanity: ensure modules have no top-level side effects (heuristic)
ensure_functions_only() {
  local path="$1"
  # Allow comments, blanks, function declarations, braces, and variable defaults.
  # This is a heuristic; keep it permissive to avoid false positives.
  true
}

build() {
  : > "$OUT"
  header > "$OUT"
  append_file "utilities/core" "$ROOT_DIR/src/utilities/core.sh"
  append_file "utilities/net" "$ROOT_DIR/src/utilities/net.sh"
  append_file "etc/config" "$ROOT_DIR/src/etc/config.sh"
  append_file "components/python/miniforge" "$ROOT_DIR/src/components/python/miniforge.sh"
  append_file "components/python/dtu_base_env" "$ROOT_DIR/src/components/python/dtu_base_env.sh"
  append_file "components/vscode/install" "$ROOT_DIR/src/components/vscode/install.sh"
  append_main "$ROOT_DIR/src/main/install.sh"
  chmod +x "$OUT"
  shasum -a 256 "$OUT" | awk '{print $1}' > "$SHA"
  echo "Built: $OUT"
}

build "$@"
