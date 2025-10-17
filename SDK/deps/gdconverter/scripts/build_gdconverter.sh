#!/usr/bin/env bash
set -euo pipefail

# Build a standalone single-file binary for a gdconverter script using Nuitka.
# Usage:
#   ./export_tscn_nuitka.sh [script_name]
# Examples:
#   ./export_tscn_nuitka.sh                  # builds export_tscn (default)
#   ./export_tscn_nuitka.sh import_spatial   # builds import_spatial
#   ./export_tscn_nuitka.sh create_godot     # builds create_godot
# Output:
#   ./dist/<script-name-with-hyphens> (Linux/macOS)
#   ./dist/<script-name-with-hyphens>.exe (Windows under bash)

# Resolve script directory (SDK/deps/gdconverter/build)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GD_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_ROOT="$(cd "${GD_ROOT}/../.." && pwd)"

SRC_DIR="${GD_ROOT}/src"
DIST_DIR="${GD_ROOT}/bin"

# Determine which script to build (basename without .py)
NAME="${1:-export_tscn}"
ENTRY_FILE="${SRC_DIR}/gdconverter/${NAME}.py"
OUTPUT_NAME="${NAME//_/-}"

if [[ ! -f "${ENTRY_FILE}" ]]; then
  echo "Error: entry file not found: ${ENTRY_FILE}" >&2
  echo "Usage: $0 [script_name]" >&2
  echo "Available examples: export_tscn, import_spatial, create_godot" >&2
  exit 1
fi

mkdir -p "${DIST_DIR}"

# Ensure Nuitka is installed in current interpreter
PYTHON_BIN=${PYTHON_BIN:-python3}
"${PYTHON_BIN}" -m pip install --upgrade pip >/dev/null 2>&1 || true
"${PYTHON_BIN}" -m pip show nuitka >/dev/null 2>&1 || "${PYTHON_BIN}" -m pip install  nuitka >/dev/null 2>&1

echo "Building ${NAME} -> ${DIST_DIR}/${OUTPUT_NAME}{,.exe}"

# Build
# Notes:
# --onefile creates a single executable. We set output dir to project-level dist.
# On macOS/Linux, the binary name will be ${OUTPUT_NAME}; on Windows, ${OUTPUT_NAME}.exe
# Ensure src is importable during compilation
export PYTHONPATH="${SRC_DIR}:${PYTHONPATH:-}"

"${PYTHON_BIN}" -m nuitka \
  --onefile \
  --standalone \
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
