#!/bin/bash
# =============================================================================
# generate.sh — Main entry point for Chinese Poetry Fortune data generation
# Orchestrates processing of all 8 poetry groups via lib/*.sh processors.
# Usage: ./generate.sh [-a|--annotated] [--no-color] [-h|--help]
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

source "${SCRIPT_DIR}/lib/constants.sh"
source "${SCRIPT_DIR}/lib/file-lists.sh"
source "${SCRIPT_DIR}/lib/format-record.sh"
source "${SCRIPT_DIR}/lib/process-json-tang.sh"
source "${SCRIPT_DIR}/lib/process-json-song.sh"
source "${SCRIPT_DIR}/lib/process-ci.sh"
source "${SCRIPT_DIR}/lib/process-others.sh"

annotated=false
# color_enabled defaults to true (set in format-record.sh via : "${color_enabled:=true}")

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Generate fortune-format data files from Chinese poetry collections.
Output files are written to the ${BUILD_DIR}/ directory.

Options:
  -a, --annotated    Include ping-ze (tone) annotations alongside poem lines
  --no-color         Disable ANSI color codes in output
  -h, --help         Show this help message and exit

Examples:
  ./generate.sh                          Plain poetry (no annotations, with color)
  ./generate.sh -a                       Poetry with ping-ze annotations
  ./generate.sh --no-color               Plain poetry, no color codes
  ./generate.sh -a --no-color            Annotated poetry, no color codes
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--annotated)
      annotated=true
      shift
      ;;
    --no-color)
      color_enabled=false
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Error: Unknown option: $1" >&2
      show_help
      exit 1
      ;;
  esac
done

mkdir -p "${BUILD_DIR}"

OUT_JSON_TANG="${BUILD_DIR}/json_tang"
OUT_JSON_SONG="${BUILD_DIR}/json_song"
OUT_CI="${BUILD_DIR}/ci"
OUT_QTS="${BUILD_DIR}/quan_tang_shi"
OUT_SHIJING="${BUILD_DIR}/shijing"
OUT_HUAJIANJI="${BUILD_DIR}/huajianji"
OUT_NANTANG="${BUILD_DIR}/nantang"
OUT_YUANQU="${BUILD_DIR}/yuanqu"

echo "Processing Tang poetry..." >&2
process_json_tang > "$OUT_JSON_TANG"

echo "Processing Song poetry..." >&2
process_json_song > "$OUT_JSON_SONG"

echo "Processing Ci lyrics..." >&2
process_ci > "$OUT_CI"

echo "Processing Quan Tang Shi..." >&2
process_qts > "$OUT_QTS"

echo "Processing Shi Jing..." >&2
process_shijing > "$OUT_SHIJING"

echo "Processing Hua Jian Ji..." >&2
process_huajianji > "$OUT_HUAJIANJI"

echo "Processing Nan Tang..." >&2
process_nantang > "$OUT_NANTANG"

echo "Processing Yuan Qu..." >&2
process_yuanqu > "$OUT_YUANQU"

OUT_ALL="${BUILD_DIR}/all"

echo "Combining all groups into ${OUT_ALL}..." >&2
cat "$OUT_JSON_TANG" "$OUT_JSON_SONG" "$OUT_CI" "$OUT_QTS" \
    "$OUT_SHIJING" "$OUT_HUAJIANJI" "$OUT_NANTANG" "$OUT_YUANQU" \
    > "$OUT_ALL"

echo "Generating .dat indexes with strfile..." >&2
if command -v strfile >/dev/null 2>&1; then
  for f in "$OUT_JSON_TANG" "$OUT_JSON_SONG" "$OUT_CI" "$OUT_QTS" \
           "$OUT_SHIJING" "$OUT_HUAJIANJI" "$OUT_NANTANG" "$OUT_YUANQU" \
           "$OUT_ALL"; do
    if [ -s "$f" ]; then
      echo "  strfile: $(basename "$f")" >&2
      strfile "$f" "${f}.dat" 2>&1 | sed 's/^/    /' >&2 || echo "  WARNING: strfile failed for $f" >&2
    else
      echo "  SKIP: $(basename "$f") is empty" >&2
    fi
  done
else
  echo "  WARNING: strfile not found — skipping .dat generation" >&2
fi

echo "" >&2
echo "=== Summary ===" >&2
total=0
for f in "$OUT_JSON_TANG" "$OUT_JSON_SONG" "$OUT_CI" "$OUT_QTS" \
         "$OUT_SHIJING" "$OUT_HUAJIANJI" "$OUT_NANTANG" "$OUT_YUANQU"; do
  count=$(grep -c '^%$' "$f" 2>/dev/null || echo 0)
  printf "  %-20s %8d records\n" "$(basename "$f")" "$count" >&2
  total=$((total + count))
done
printf "  %-20s %8d records\n" "TOTAL" "$total" >&2
echo "Done. ${total} total fortune records in ${BUILD_DIR}/" >&2
