# =============================================================================
# Process Tang Poetry JSON Files
# Dependencies: lib/constants.sh, lib/format-record.sh, lib/file-lists.sh
#
# Provides process_json_tang() to convert Tang poetry JSON files into
# fortune-ready records with optional ping-ze annotation via strains lookup.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd -P)"
source "${SCRIPT_DIR}/lib/constants.sh"
source "${SCRIPT_DIR}/lib/format-record.sh"
source "${SCRIPT_DIR}/lib/file-lists.sh"

# _process_json_plain — generate unannotated fortune records from one Tang JSON file
#   $1 = path to JSON file
_process_json_plain() {
  local file="$1"
  local header=""
  local body_lines=()

  jq -r '
    .[] | select(.paragraphs | length > 0) |
    "\(.title)|\(.author)",
    (.paragraphs[]),
    "==EOR=="
  ' "$file" | while IFS= read -r line; do
    if [[ "$line" == "==EOR==" ]]; then
      format_fortune_record "$header" "${body_lines[@]}"
      header=""
      body_lines=()
    elif [[ -z "$header" ]]; then
      IFS='|' read -r title author <<< "$line"
      header=$(format_fortune_header "$title" "$author")
    else
      body_lines+=("$line")
    fi
  done
}

# _process_json_with_strains — generate annotated fortune records with ping-ze
#   $1 = path to JSON file
#   $2 = path to strains JSON file
_process_json_with_strains() {
  local file="$1"
  local strains_file="$2"

  if [[ ! -f "$strains_file" ]]; then
    echo "  warning: strains file not found: ${strains_file}, falling back to plain" >&2
    _process_json_plain "$file"
    return
  fi

  local header=""
  local body_lines=()
  local record_mode=""

  jq -r --slurpfile strains "$strains_file" '
    ($strains[0] | map({(.id): .strains}) | add) as $s_lookup |
    .[] | select(.paragraphs | length > 0) |
    ($s_lookup[.id]) as $s |
    if $s then
      "\(.title)|\(.author)|ANNOTATED",
      ([.paragraphs, $s] | transpose | map(
        if .[1] then "\(.[0])|\(.[1])" else "\(.[0])|__NOSTRAIN__" end
      ) | .[]),
      "==EOR=="
    else
      "\(.title)|\(.author)|PLAIN",
      (.paragraphs[]),
      "==EOR=="
    end
  ' "$file" | while IFS= read -r line; do
    if [[ "$line" == "==EOR==" ]]; then
      format_fortune_record "$header" "${body_lines[@]}"
      header=""
      body_lines=()
      record_mode=""
    elif [[ -z "$header" ]]; then
      IFS='|' read -r title author record_mode <<< "$line"
      header=$(format_fortune_header "$title" "$author")
    else
      if [[ "$record_mode" == "ANNOTATED" ]]; then
        local poem_line strain_line
        IFS='|' read -r poem_line strain_line <<< "$line"
        if [[ "$strain_line" == "__NOSTRAIN__" ]]; then
          body_lines+=("$poem_line")
        else
          body_lines+=("$(format_annotated_line "$poem_line" "$strain_line")")
        fi
      else
        body_lines+=("$line")
      fi
    fi
  done
}

# process_json_tang — main entry: convert all Tang JSON files to fortune records
#   Reads global $annotated variable (set by generate.sh -a flag)
# Iterates over FILES_JSON_TANG array (58 files, poet.tang.{0,1000,...,57000}.json).
# Each record uses format_fortune_header for the title/author line and
# format_fortune_record for the complete fortune entry including % delimiter.
process_json_tang() {
  local annotated="${annotated:-false}"

  for file in "${FILES_JSON_TANG[@]}"; do
    local base_name
    base_name=$(basename "$file")
    echo "  json_tang: $base_name" >&2

    if [[ "$annotated" == "true" ]]; then
      _process_json_with_strains "$file" "${DATA_ROOT}/strains/json/${base_name}"
    else
      _process_json_plain "$file"
    fi
  done
}
