# =============================================================================
# Formatting Library for Fortune Records
# Dependencies: lib/constants.sh (C_CYAN_BOLD, C_GREEN, C_RESET, color_enabled)
# =============================================================================

_this_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
if [ -z "${C_CYAN_BOLD:-}" ]; then
  source "${_this_dir}/constants.sh"
fi
: "${color_enabled:=true}"

# format_fortune_header — print formatted title/author header line
#   $1 = title  (default: "无题")
#   $2 = author (default: "佚名")
format_fortune_header() {
  local title="${1:-无题}"
  local author="${2:-佚名}"

  if [[ "$color_enabled" == "true" ]]; then
    printf "${C_CYAN_BOLD}${title} — ${author}${C_RESET}\n"
  else
    printf "${title} — ${author}\n"
  fi
}

# format_fortune_record — output a complete fortune record with % delimiter
#   $1 = header line (pre-formatted)
#   $@ = remaining positional args are body lines
#
# Usage: format_fortune_record "$header" "${body_lines[@]}"
# Output: {header}\n\n{body lines...}\n\n%\n   (% is ALWAYS alone, NO ANSI codes)
format_fortune_record() {
  local header="$1"
  shift
  local body_lines=("$@")

  printf "%s\n\n" "$header"

  local line
  for line in "${body_lines[@]}"; do
    printf "%s\n" "$line"
  done

  printf "\n%%\n"
}

# format_annotated_line — print poem line with ping-ze annotation alongside
#   $1 = poem line
#   $2 = strain / ping-ze line
format_annotated_line() {
  local poem_line="$1"
  local strain_line="$2"

  if [[ "$color_enabled" == "true" ]]; then
    printf "${poem_line}${C_GREEN}${strain_line}${C_RESET}\n"
  else
    printf "${poem_line}${strain_line}\n"
  fi
}
