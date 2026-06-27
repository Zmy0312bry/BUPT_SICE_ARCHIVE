#!/bin/bash

REF_PI="3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679"
MAX_ITER_TIME=15
SCALE=200

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Compute all PI approximations via Ramanujan formula in single bc call
PI_VALUES=()
while IFS= read -r line; do
    [[ -n "$line" ]] && PI_VALUES+=("$line")
done < <(BC_LINE_LENGTH=0 bc -l <<EOD
scale=${SCALE}
define fact(n) {
    auto i, r
    r = 1
    for (i = 2; i <= n; i++) {
        r = r * i
    }
    return r
}
define ramanujan_pi(iter) {
    auto s, k, f4k, fk, num, den
    s = 0
    for (k = 0; k <= iter; k++) {
        f4k = fact(4*k)
        fk = fact(k)
        num = f4k * (1103 + 26390*k)
        den = fk^4 * 396^(4*k)
        s = s + num / den
    }
    return 9801 / (sqrt(8) * s)
}
for (k = 0; k < ${MAX_ITER_TIME}; k++) {
    ramanujan_pi(k)
    print "\n"
}
quit
EOD
)

# Print colored PI: prefix in green, suffix in red
# Returns 0 (true) if all REF_PI chars matched, 1 (false) otherwise
print_colored_pi() {
    local cal="$1"
    local i c1 c2 prefix_len=0 color_changed=0

    while (( prefix_len < ${#cal} && prefix_len < ${#REF_PI} )); do
        [[ "${cal:$prefix_len:1}" == "${REF_PI:$prefix_len:1}" ]] || break
        ((prefix_len++))
    done

    # Print green prefix
    if (( prefix_len > 0 )); then
        printf "${GREEN}%s${NC}" "${cal:0:$prefix_len}"
    fi

    # Print red suffix, truncated to REF_PI length
    local tail_len=$((${#REF_PI} - prefix_len))
    if (( tail_len > 0 && prefix_len < ${#cal} )); then
        printf "${RED}%s${NC}" "${cal:$prefix_len:$tail_len}"
    fi

    # Return true if all REF_PI chars matched
    if (( prefix_len >= ${#REF_PI} )); then
        return 0
    else
        return 1
    fi
}

# Line 1: Standard PI reference in blue
printf "${BLUE}Standard PI:              ${REF_PI}${NC}\n"

# Line 2: separator line matching total visible length of line 1
LABEL_PREFIX="Standard PI:              "
TOTAL_LEN=$((${#LABEL_PREFIX} + ${#REF_PI}))
SEP=$(printf "${BLUE}%*s${NC}" "$TOTAL_LEN" '' | tr ' ' '-')
echo "$SEP"

# Lines 3+: iteration results with color-coded digits
for ((k=0; k<MAX_ITER_TIME; k++)); do
    CAL_PI="${PI_VALUES[$k]}"
    if (( k < 10 )); then
        printf "${BLUE}第%d次迭代：${NC}               " "$k"
    else
        printf "${BLUE}第%d次迭代：${NC}              " "$k"
    fi
    if print_colored_pi "$CAL_PI"; then
        echo
        break
    fi
    echo
done
