#!/usr/bin/env bash
# Logging and common utility functions

# Colors (only if terminal supports it)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

log_ok() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*" >&2
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

log_skip() {
    echo -e "${BLUE}○${NC} $*"
}

log_info() {
    echo -e "${BLUE}→${NC} $*"
}

# Check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Get the directory where appctl is installed
get_appctl_dir() {
    local script_path
    script_path="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    # Go up from core/ or handlers/ to appctl/
    dirname "$script_path"
}
