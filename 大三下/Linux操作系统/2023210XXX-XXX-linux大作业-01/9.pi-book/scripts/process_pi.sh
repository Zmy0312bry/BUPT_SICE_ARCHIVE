#!/bin/bash
set -euo pipefail

DATA_FILE="assets/pi1000000.txt"
DIGITS_PER_LINE=100
NUM_CHAPTERS=10
GROUP_SIZE=10
LINES_PER_PAGE=100
OUTPUT_DIR="./build"

usage() {
    echo "Usage: $0 [-f pi_data_file] [-l digits_per_line] [-c num_chapters] [-g group_size]"
    echo "  -f  Input pi data file (default: assets/pi1000000.txt)"
    echo "  -l  Digits per output line (default: 100, must be multiple of -g)"
    echo "  -c  Number of chapters (default: 10)"
    echo "  -g  Group size for spacing (default: 10)"
    exit 1
}

while getopts "f:l:c:g:h" opt; do
    case $opt in
        f) DATA_FILE="$OPTARG" ;;
        l) DIGITS_PER_LINE="$OPTARG" ;;
        c) NUM_CHAPTERS="$OPTARG" ;;
        g) GROUP_SIZE="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

if [ ! -f "$DATA_FILE" ]; then
    echo "Error: data file not found: $DATA_FILE"
    exit 1
fi

if [ $(( DIGITS_PER_LINE % GROUP_SIZE )) -ne 0 ]; then
    echo "Error: digits_per_line ($DIGITS_PER_LINE) must be divisible by group_size ($GROUP_SIZE)"
    exit 1
fi

if [ "$NUM_CHAPTERS" -lt 1 ]; then
    echo "Error: num_chapters must be >= 1"
    exit 1
fi

GROUPS_PER_LINE=$(( DIGITS_PER_LINE / GROUP_SIZE ))

mkdir -p "$OUTPUT_DIR"

RAW=$(tr -d '\n\r \t' < "$DATA_FILE")
# Strip "3." prefix — keep only decimal digits
DECIMAL_DIGITS="${RAW#3.}"

TOTAL_DIGITS=${#DECIMAL_DIGITS}

if [ "$TOTAL_DIGITS" -eq 0 ]; then
    echo "Error: no digits found in $DATA_FILE"
    exit 1
fi

echo "============================================"
echo "  Pi Data Processor"
echo "============================================"
echo "Input file:       $DATA_FILE"
echo "Total digits:     $TOTAL_DIGITS"
echo "Chapters:         $NUM_CHAPTERS"
echo "Digits per line:  $DIGITS_PER_LINE"
echo "Group size:       $GROUP_SIZE"
echo "Lines per page:   $LINES_PER_PAGE"
echo "Digits per page:  $(( DIGITS_PER_LINE * LINES_PER_PAGE ))"
echo "============================================"

DIGITS_PER_PAGE=$(( DIGITS_PER_LINE * LINES_PER_PAGE ))
DIGITS_PER_CHAPTER=$(( TOTAL_DIGITS / NUM_CHAPTERS ))

echo "Digits/chapter:   $DIGITS_PER_CHAPTER"
echo "============================================"

printf '\\newcommand{\\totaldigits}{%d}\n' "$TOTAL_DIGITS" > "$OUTPUT_DIR/total_digits.tex"

> "$OUTPUT_DIR/chapters.tex"

CHAPTER_START=0

for ((chapter=1; chapter<=NUM_CHAPTERS; chapter++)); do
    if [ $chapter -eq $NUM_CHAPTERS ]; then
        CHAPTER_DIGITS=$(( TOTAL_DIGITS - CHAPTER_START ))
    else
        CHAPTER_DIGITS=$DIGITS_PER_CHAPTER
    fi

    CSTART=$(printf "%06d" $CHAPTER_START)
    CEND_TMP=$(( CHAPTER_START + CHAPTER_DIGITS - 1 ))
    CEND=$(printf "%06d" $CEND_TMP)

    CHAPTER_TITLE="第${chapter}章: ${CSTART}--${CEND}位"

    echo "Chapter $chapter: $CSTART -- $CEND"

    cat >> "$OUTPUT_DIR/chapters.tex" << EOF
\\startchapter{${CHAPTER_TITLE}}
{\\digitpagefont
\\input{build/data_ch${chapter}.tex}
}

EOF

    DF="$OUTPUT_DIR/data_ch${chapter}.tex"
    > "$DF"

    format_chunk() {
        # Args: $1 = digit string, $2 = start_pos (absolute), $3 = output file
        local chunk="$1"
        local start="$2"
        local outfile="$3"

        printf '%s' "$chunk" | \
            sed "s/.\{${GROUP_SIZE}\}/& /g" | \
            sed 's/ $//' | \
            tr ' ' '\n' | \
            awk -v n="$GROUPS_PER_LINE" \
                -v pos="$start" \
                -v dpl="$DIGITS_PER_LINE" \
                -v dpp="$DIGITS_PER_PAGE" '
            {
                groups[++gc] = $0
            }
            END {
                out = 0
                for (i = 1; i <= gc; i += n) {
                    out++
                    line_pos = pos + (out - 1) * dpl

                    line_digits = 0
                    for (j = 0; j < n && i+j <= gc; j++) {
                        line_digits += length(groups[i+j])
                    }
                    line_end = line_pos + line_digits - 1

                    # Anchor every 1000 digits for index \hyperlink jumps
                    if (line_pos % 1000 == 0) {
                        idx_start = line_pos
                        idx_end = line_pos + 999
                        printf "\\idxanchor{%06d--%06d}\n", idx_start, idx_end
                    }

                    # Page break every LINES_PER_PAGE except chapter boundaries
                    if (line_pos > 0 && line_pos % dpp == 0 && line_pos % 100000 != 0) {
                        printf "\\newpage\n"
                    }

                    printf "\\digitsline{%06d}{%06d}", line_pos, line_end
                    if (line_pos == 0)
                        printf "3.\\hfil "
                    else
                        printf "\\phantom{3.}\\hfil "
                    for (j = 0; j < n && i+j <= gc; j++) {
                        printf "%s", groups[i+j]
                        if (j < n-1 && i+j < gc) printf "\\hfil "
                    }
                    printf "\\par\n"
                }
            }' >> "$outfile"
    }

    CHUNK="${DECIMAL_DIGITS:$CHAPTER_START:$CHAPTER_DIGITS}"
    format_chunk "$CHUNK" "$CHAPTER_START" "$DF"

    CHAPTER_START=$(( CHAPTER_START + CHAPTER_DIGITS ))
done

# Generate index file with \hyperlink for absolute position jumps
> "$OUTPUT_DIR/digit_index.tex"
{
    printf '\\begin{theindex}\n'

    CHAPTER_START=0
    for ((chapter=1; chapter<=NUM_CHAPTERS; chapter++)); do
        if [ $chapter -eq $NUM_CHAPTERS ]; then
            CHAPTER_DIGITS=$(( TOTAL_DIGITS - CHAPTER_START ))
        else
            CHAPTER_DIGITS=$DIGITS_PER_CHAPTER
        fi

        CSTART=$(printf "%06d" $CHAPTER_START)
        CEND=$(( CHAPTER_START + CHAPTER_DIGITS - 1 ))
        CENDF=$(printf "%06d" $CEND)

        printf '  \\item 第%d章: %s--%s位\n' "$chapter" "$CSTART" "$CENDF"

        pos=$CHAPTER_START
        while [ $pos -lt $(( CHAPTER_START + CHAPTER_DIGITS )) ]; do
            pstart=$(printf "%06d" $pos)
            pend=$(( pos + 999 ))
            if [ $pend -ge $(( CHAPTER_START + CHAPTER_DIGITS )) ]; then
                pend=$(( CHAPTER_START + CHAPTER_DIGITS - 1 ))
            fi
            pendf=$(printf "%06d" $pend)
            printf '    \\subitem \\hyperlink{idx:%s--%s}{%s--%s}\n' "$pstart" "$pendf" "$pstart" "$pendf"
            pos=$(( pos + 1000 ))
        done

        CHAPTER_START=$(( CHAPTER_START + CHAPTER_DIGITS ))
    done

    printf '\\end{theindex}\n'
} >> "$OUTPUT_DIR/digit_index.tex"

echo ""
echo "Output files written to $OUTPUT_DIR/"
echo "  total_digits.tex"
echo "  chapters.tex"
echo "  digit_index.tex"
for ((chapter=1; chapter<=NUM_CHAPTERS; chapter++)); do
    echo "  data_ch${chapter}.tex"
done
echo "Done."
