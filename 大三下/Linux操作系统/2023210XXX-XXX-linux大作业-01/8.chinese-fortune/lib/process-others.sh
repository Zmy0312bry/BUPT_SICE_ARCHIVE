#!/bin/bash
# =============================================================================
# Process "Others" — QTS, Shijing, Huajianji, Nantang, Yuanqu
# Each function uses ONE jq invocation per file. Paragraphs joined with
# unit separator (\x1f) inside jq, split back in shell via IFS=$'\x1f'.
# Dependencies: lib/constants.sh, lib/file-lists.sh, lib/format-record.sh
# =============================================================================

set -euo pipefail

_others_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd -P)"
source "${_others_script_dir}/lib/constants.sh"
source "${_others_script_dir}/lib/file-lists.sh"
source "${_others_script_dir}/lib/format-record.sh"

# --- Shared helper: process file with (title, author, paragraphs) schema ---
_process_std_schema() {
    local file="$1" label="$2"
    echo "[${label}] ${file}" >&2

    jq -r '
        .[] | select(.paragraphs != null and (.paragraphs | type == "array") and (.paragraphs | length > 0)) |
        [.title // "无题", .author // "佚名", (.paragraphs | join("\u001f"))] |
        @tsv
    ' "$file" | while IFS=$'\t' read -r title author paras_joined; do
        [[ -z "$paras_joined" || "$paras_joined" == "[]" || "$paras_joined" == "null" ]] && continue
        [[ -z "$title" || "$title" == "null" ]] && title="无题"
        [[ -z "$author" || "$author" == "null" ]] && author="佚名"

        local header
        header=$(format_fortune_header "$title" "$author")

        IFS=$'\x1f' read -ra para_lines <<< "$paras_joined"
        format_fortune_record "$header" "${para_lines[@]}"
    done
}

# =============================================================================
# process_qts — 全唐诗 (Quan Tang Shi), 900 files by volume
# =============================================================================
process_qts() {
    local file
    for file in "${FILES_QTS[@]}"; do
        [[ -f "$file" ]] || { echo "[WARN] Missing: $file" >&2; continue; }
        _process_std_schema "$file" "QTS"
    done
}

# =============================================================================
# process_shijing — 诗经, 1 file, uses "content" field (NOT "paragraphs"),
# NO author — substitutes with "chapter：section"
# =============================================================================
process_shijing() {
    local file
    for file in "${FILES_SHIJING[@]}"; do
        [[ -f "$file" ]] || { echo "[WARN] Missing: $file" >&2; continue; }
        echo "[ShiJing] ${file}" >&2

        jq -r '
            .[] | select(.content != null and (.content | type == "array") and (.content | length > 0)) |
            [.title // "无题", .chapter // "", .section // "", (.content | join("\u001f"))] |
            @tsv
        ' "$file" | while IFS=$'\t' read -r title chapter section content_joined; do
            [[ -z "$content_joined" || "$content_joined" == "[]" || "$content_joined" == "null" ]] && continue
            [[ -z "$title" || "$title" == "null" ]] && title="无题"
            [[ -z "$chapter" ]] && chapter=""
            [[ -z "$section" ]] && section=""

            local author_sub="${chapter}：${section}"
            local header
            header=$(format_fortune_header "$title" "$author_sub")

            IFS=$'\x1f' read -ra content_lines <<< "$content_joined"
            format_fortune_record "$header" "${content_lines[@]}"
        done
    done
}

# =============================================================================
# process_huajianji — 花间集, 10 files (huajianji-0-preface already excluded)
# =============================================================================
process_huajianji() {
    local file
    for file in "${FILES_HUAJIANJI[@]}"; do
        [[ -f "$file" ]] || { echo "[WARN] Missing: $file" >&2; continue; }
        _process_std_schema "$file" "Huajianji"
    done
}

# =============================================================================
# process_nantang — 南唐二主词, 1 file (only poetrys.json)
# =============================================================================
process_nantang() {
    local file
    for file in "${FILES_NANTANG[@]}"; do
        [[ -f "$file" ]] || { echo "[WARN] Missing: $file" >&2; continue; }
        _process_std_schema "$file" "NanTang"
    done
}

# =============================================================================
# process_yuanqu — 元曲, 1 file, has extra .dynasty field (ignored)
# =============================================================================
process_yuanqu() {
    local file
    for file in "${FILES_YUANQU[@]}"; do
        [[ -f "$file" ]] || { echo "[WARN] Missing: $file" >&2; continue; }
        _process_std_schema "$file" "YuanQu"
    done
}
