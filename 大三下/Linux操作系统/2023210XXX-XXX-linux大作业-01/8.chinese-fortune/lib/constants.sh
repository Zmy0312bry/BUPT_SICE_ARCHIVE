# lib/constants.sh — Pure constants/settings (no processing logic)
# Source via: source lib/constants.sh

# ANSI color escape codes (single quotes to prevent premature expansion)
C_CYAN_BOLD='\033[1;36m'
C_GREEN='\033[32m'
C_RESET='\033[0m'

# Path constants
BUILD_DIR='build'
DATA_ROOT='poetry'
STRAINS_DIR="${DATA_ROOT}/strains/json"

# Overridable via FORTUNE_DIR env var
FORTUNE_DIR="${FORTUNE_DIR:-/opt/homebrew/Cellar/fortune/9708/share/games/fortunes}"
