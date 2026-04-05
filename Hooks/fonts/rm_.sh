#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../includes/functions.sh
source "$SCRIPT_DIR/../../includes/functions.sh"
# Common helpers from includes/functions.sh.


# ==============================================================================
# Fonts Clean Hook
# ==============================================================================

FONTS_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fonts"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
LOG_FILE="$LOG_DIR/fonts-hook.log"

DRY_RUN=0
DEBUG=0
USE_SPINNER=1

usage() {
    cat <<'EOF'
Usage: rm_.sh [--dry-run|-n] [--debug|-d] [--no-spinner] [--help|-h]

Options:
  -n, --dry-run    Show what would run, but do not execute changes
  -d, --debug      Verbose output; show commands and command output
      --no-spinner Disable spinner/progress animation
  -h, --help       Show this help
EOF
}

for arg in "$@"; do
    case "$arg" in
        -n|--dry-run)
            DRY_RUN=1
            ;;
        -d|--debug)
            DEBUG=1
            ;;
        --no-spinner)
            USE_SPINNER=0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            usage >&2
            exit 2
            ;;
    esac
done

hook_init_defaults

info "Running fonts clean hook"
if (( DRY_RUN )); then
    info "Dry-run mode enabled"
fi
if (( DEBUG )); then
    info "Debug mode enabled"
fi

run_cmd "Remove fonts config directory" rm -rf "$FONTS_CONFIG_DIR"

info "Fonts clean hook complete"
