#!/bin/bash
# =============================================================================
# CI Song Processor — process_ci()
# Reads ci.song.*.json files and outputs formatted fortune records to stdout.
#
# Ci entries have: {author, paragraphs[], rhythmic} — NO title field, NO strains.
# Uses rhythmic (词牌名) as the title for fortune headers.
#
# Dependencies: lib/constants.sh, lib/file-lists.sh, lib/format-record.sh
# =============================================================================

_ci_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd -P)"
source "${_ci_script_dir}/lib/constants.sh"
source "${_ci_script_dir}/lib/file-lists.sh"
source "${_ci_script_dir}/lib/format-record.sh"

# process_ci — iterate over ALL FILES_CI, output fortune records to stdout
# Uses one jq invocation per file (paragraphs joined with unit separator 0x1f)
process_ci() {
    local total_files=${#FILES_CI[@]}
    local file_count=0
    local record_count=0

    for ci_file in "${FILES_CI[@]}"; do
        file_count=$((file_count + 1))
        echo "[${file_count}/${total_files}] ${ci_file}" >&2

        while IFS=$'\t' read -r author rhythmic paras_joined; do
            [[ -z "$paras_joined" || "$paras_joined" == "[]" || "$paras_joined" == "null" ]] && continue
            [[ -z "$author" || "$author" == "null" ]] && author="佚名"
            [[ -z "$rhythmic" || "$rhythmic" == "null" ]] && rhythmic="无题"

            local header
            header=$(format_fortune_header "$rhythmic" "$author")

            IFS=$'\x1f' read -ra para_lines <<< "$paras_joined"
            format_fortune_record "$header" "${para_lines[@]}"

            record_count=$((record_count + 1))
        done < <(jq -r '
            .[] | select(.paragraphs != null and (.paragraphs | type == "array") and (.paragraphs | length > 0)) |
            [.author // "佚名", .rhythmic // "无题", (.paragraphs | join("\u001f"))] |
            @tsv
        ' "$ci_file")
    done

    echo "Done: ${record_count} records from ${file_count} files." >&2
}
