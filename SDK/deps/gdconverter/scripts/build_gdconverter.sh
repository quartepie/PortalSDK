#!/usr/bin/env bash
set -euo pipefail

# Build a single-file binary for a gdconverter script using Nuitka.
# Usage:
#   ./build_gdconverter.sh [script_name] [output_name]
# Examples:
#   ./build_gdconverter.sh                  # builds export_tscn (default)
#   ./build_gdconverter.sh import_spatial   # builds import_spatial
#   ./build_gdconverter.sh create_godot     # builds create_godot
# Output:
#   ./bin/<script-name-with-hyphens> (Linux/macOS)
#   ./bin/<script-name-with-hyphens>.exe (Windows under bash)

# Resolve script directory (SDK/deps/gdconverter/scripts)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GD_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_ROOT="$(cd "${GD_ROOT}/../.." && pwd)"

SRC_DIR="${GD_ROOT}/src"
DIST_DIR="${GD_ROOT}/bin"

# Determine which script to build (basename without .py)
NAME="${1:-export_tscn}"
ENTRY_FILE="${SRC_DIR}/gdconverter/${NAME}.py"
# Allow specifying custom output file name as second argument; default to same as input NAME
OUTPUT_NAME="${2:-$NAME}"

if [[ ! -f "${ENTRY_FILE}" ]]; then
  echo "Error: entry file not found: ${ENTRY_FILE}" >&2
  echo "Usage: $0 [script_name] [output_name]" >&2
  echo "Available examples: export_tscn, import_spatial, create_godot" >&2
  exit 1
fi

mkdir -p "${DIST_DIR}"

# Choose Python binary with fallback for Windows where python3 may not exist
if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN=${PYTHON_BIN:-python3}
else
  PYTHON_BIN=${PYTHON_BIN:-python}
fi

# Detect platform for optional dependencies
uname_s=$(uname -s || echo unknown)
# Ensure Nuitka (and patchelf on Linux) is installed in current interpreter
"${PYTHON_BIN}" -m pip install --upgrade pip >/dev/null 2>&1 || true
case "$uname_s" in
  Linux*)   "${PYTHON_BIN}" -m pip show nuitka >/dev/null 2>&1 || "${PYTHON_BIN}" -m pip install nuitka patchelf >/dev/null 2>&1 ;;
  *)        "${PYTHON_BIN}" -m pip show nuitka >/dev/null 2>&1 || "${PYTHON_BIN}" -m pip install nuitka >/dev/null 2>&1 ;;
 esac

echo "Building ${NAME} -> ${DIST_DIR}/${OUTPUT_NAME}{,.exe}"

# Ensure src is importable during compilation (POSIX path separator)
export PYTHONPATH="${SRC_DIR}:${PYTHONPATH:-}"

# Build: use --onefile only (no --standalone) to avoid *.dist folder
"${PYTHON_BIN}" -m nuitka \
  --onefile \
  --output-dir="${DIST_DIR}" \
  --lto=no \
  --include-package=gdconverter \
  --noinclude-numba-mode=nofollow \
  --nofollow-import-to=pytest \
  --remove-output \
  --output-filename="${OUTPUT_NAME}" \
  "${ENTRY_FILE}"

# Print resulting artifact path(s)
echo "Built artifacts in: ${DIST_DIR}"
ls -l "${DIST_DIR}" | sed 's/^/  /'
