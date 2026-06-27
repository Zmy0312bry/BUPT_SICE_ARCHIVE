# =============================================================================
# File Lists — explicit file path arrays for ALL 8 data groups
# Dependencies: lib/constants.sh (DATA_ROOT)
# Source via: source lib/file-lists.sh  (after sourcing constants.sh)
# =============================================================================
#
# Each array holds the full (relative) path to every data file in its group,
# excluding dangerous non-poem files (author info, intros, prefaces, etc.).
#
# Arrays defined:
#   FILES_JSON_TANG   — poet.tang.{0,1000,...,57000}.json          (58 files)
#   FILES_JSON_SONG   — poet.song.{0,1000,...,254000}.json        (255 files)
#   FILES_CI          — ci.song.{0,1000,...,21000}.json + 2019y   (23 files)
#   FILES_QTS         — quan_tang_shi/json/{001..900}.json       (900 files)
#   FILES_SHIJING     — shijing.json                               (1 file)
#   FILES_HUAJIANJI   — huajianji-{1..9,x}-juan.json             (10 files)
#   FILES_NANTANG     — wudai/nantang/poetrys.json                 (1 file)
#   FILES_YUANQU      — yuanqu.json                                (1 file)
# =============================================================================

# --- JSON Tang (58 files) -----------------------------------------------------
# Pattern: poet.tang.{0,1000,2000,...,57000}.json
# Excludes: authors.tang.json, 唐诗三百首.json, 唐诗补录.json
FILES_JSON_TANG=()
for _i in $(seq 0 1000 57000); do
  FILES_JSON_TANG+=("${DATA_ROOT}/json/poet.tang.${_i}.json")
done

# --- JSON Song (255 files) ----------------------------------------------------
# Pattern: poet.song.{0,1000,2000,...,254000}.json
# Excludes: authors.song.json
FILES_JSON_SONG=()
for _i in $(seq 0 1000 254000); do
  FILES_JSON_SONG+=("${DATA_ROOT}/json/poet.song.${_i}.json")
done

# --- CI Song (23 files) -------------------------------------------------------
# Pattern: ci.song.{0,1000,...,21000}.json + ci.song.2019y.json
# Excludes: author.song.json, 宋词三百首.json
FILES_CI=()
for _i in $(seq 0 1000 21000); do
  FILES_CI+=("${DATA_ROOT}/ci/ci.song.${_i}.json")
done
FILES_CI+=("${DATA_ROOT}/ci/ci.song.2019y.json")

# --- Quan Tang Shi (900 files) ------------------------------------------------
# Pattern: {001..900}.json
FILES_QTS=()
for _i in $(seq -w 1 900); do
  FILES_QTS+=("${DATA_ROOT}/quan_tang_shi/json/${_i}.json")
done

# --- Shi Jing (1 file) --------------------------------------------------------
FILES_SHIJING=(
  "${DATA_ROOT}/shijing/shijing.json"
)

# --- Hua Jian Ji (10 files) ---------------------------------------------------
# Explicit entries: huajianji-{1..9}-juan.json + huajianji-x-juan.json
# Excludes: huajianji-0-preface.json (has NO paragraphs field)
FILES_HUAJIANJI=(
  "${DATA_ROOT}/wudai/huajianji/huajianji-1-juan.json"
  "${DATA_ROOT}/wudai/huajianji/huajianji-2-juan.json"
  "${DATA_ROOT}/wudai/huajianji/huajianji-3-juan.json"
  "${DATA_ROOT}/wudai/huajianji/huajianji-4-juan.json"
  "${DATA_ROOT}/wudai/huajianji/huajianji-5-juan.json"
  "${DATA_ROOT}/wudai/huajianji/huajianji-6-juan.json"
  "${DATA_ROOT}/wudai/huajianji/huajianji-7-juan.json"
  "${DATA_ROOT}/wudai/huajianji/huajianji-8-juan.json"
  "${DATA_ROOT}/wudai/huajianji/huajianji-9-juan.json"
  "${DATA_ROOT}/wudai/huajianji/huajianji-x-juan.json"
)

# --- Nan Tang (1 file) --------------------------------------------------------
# Only poetrys.json — excludes authors.json and intro.json
FILES_NANTANG=(
  "${DATA_ROOT}/wudai/nantang/poetrys.json"
)

# --- Yuan Qu (1 file) ---------------------------------------------------------
FILES_YUANQU=(
  "${DATA_ROOT}/yuanqu/yuanqu.json"
)
