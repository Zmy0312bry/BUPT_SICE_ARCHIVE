#!/bin/bash
# =============================================================================
# lib/process-json-song.sh — Process Song poetry JSON files
# Part of generate.sh pipeline. Sources dependencies, defines process_json_song().
#
# Processes FILES_JSON_SONG (255 files, poet.song.{0..254000}.json).
# Each file is a JSON array of ~1000 poem records with {author, title, paragraphs, id}.
#
# Annotated mode (annotated=true): appends ping-ze (tone) patterns from
#   strains/json/poet.song.{N}.json, matched by UUID id field.
# Plain mode: outputs poem text only.
# =============================================================================

set -euo pipefail

# --- Source dependencies (idempotent) -----------------------------------------
if [ -z "${DATA_ROOT:-}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd -P)"
  source "${SCRIPT_DIR}/lib/constants.sh"
  source "${SCRIPT_DIR}/lib/file-lists.sh"
  source "${SCRIPT_DIR}/lib/format-record.sh"
fi

# =============================================================================
# process_json_song — output formatted Song poetry fortune records to stdout
#
# Globals (read):
#   annotated     — if "true", enable ping-ze annotation (set by generate.sh)
#   color_enabled — if "true", use ANSI color codes (set in format-record.sh)
#   FILES_JSON_SONG — array of 255 file paths
#   STRAINS_DIR    — path to strains JSON directory
#
# Output: fortune-format records (header + body + % delimiter) to stdout.
# Progress: file-level status messages to stderr.
# =============================================================================
process_json_song() {
  local total=${#FILES_JSON_SONG[@]}
  local idx=0
  local json_file base_name strains_file
  local title author id paras_joined strains_joined
  local header para_lines strain_lines formatted_lines i

  for json_file in "${FILES_JSON_SONG[@]}"; do
    idx=$((idx + 1))
    echo "[${idx}/${total}] Processing: $(basename "$json_file")" >&2

    base_name="$(basename "$json_file")"
    strains_file="${STRAINS_DIR}/${base_name}"

    if [[ "${annotated:-false}" == "true" ]] && [[ -f "$strains_file" ]]; then
      # ---- Annotated mode: join poems with strains by UUID ------------------
      jq -r --slurpfile strains "$strains_file" '
        .[] | select(.paragraphs != null and (.paragraphs | type == "array") and (.paragraphs | length > 0)) |
        . as {title: $t, author: $a, id: $id, paragraphs: $p} |
        [
          ($t // "无题"),
          ($a // "佚名"),
          $id,
          ($p | join("\u001f")),
          (
            (($strains[0][] | select(.id == $id) | .strains) // null) as $s |
            if $s then ($s | join("\u001f")) else "" end
          )
        ] | @tsv
      ' "$json_file" | while IFS=$'\t' read -r title author id paras_joined strains_joined; do
        header="$(format_fortune_header "$title" "$author")"
        IFS=$'\x1f' read -ra para_lines <<< "$paras_joined"

        if [[ -n "$strains_joined" ]]; then
          IFS=$'\x1f' read -ra strain_lines <<< "$strains_joined"
          formatted_lines=()
          for i in "${!para_lines[@]}"; do
            formatted_lines+=("$(format_annotated_line "${para_lines[$i]}" "${strain_lines[$i]:-}")")
          done
          format_fortune_record "$header" "${formatted_lines[@]}"
        else
          echo "Warning: UUID ${id} not found in ${base_name} strains" >&2
          format_fortune_record "$header" "${para_lines[@]}"
        fi
      done

    else
      # ---- Plain mode: poem text only ---------------------------------------
      [[ "${annotated:-false}" == "true" ]] && \
        echo "Warning: Strains file not found: ${strains_file}" >&2

      jq -r '
        .[] | select(.paragraphs != null and (.paragraphs | type == "array") and (.paragraphs | length > 0)) |
        [.title // "无题", .author // "佚名", (.paragraphs | join("\u001f"))] |
        @tsv
      ' "$json_file" | while IFS=$'\t' read -r title author paras_joined; do
        header="$(format_fortune_header "$title" "$author")"
        IFS=$'\x1f' read -ra para_lines <<< "$paras_joined"
        format_fortune_record "$header" "${para_lines[@]}"
      done
    fi
  done
}
