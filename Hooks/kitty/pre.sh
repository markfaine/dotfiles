#!/usr/bin/env bash

# This hook ensures the required directory structure for creating symlinks

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../includes/functions.sh
source "$SCRIPT_DIR/../../includes/functions.sh"
# Common helpers from includes/functions.sh.


# ==============================================================================
# Kitty Pre Hook
# ==============================================================================

LOCAL_APPS_DIR="${XDG_DATA_HOME:-${ZDOTDIR:-$HOME}/.local/share}/applications"
LOG_DIR="${XDG_STATE_HOME:-${ZDOTDIR:-$HOME}/.local/state}"
LOG_FILE="$LOG_DIR/kitty-pre-hook.log"

DRY_RUN=0
DEBUG=0
USE_SPINNER=1

usage() {
    cat <<'EOF'
Usage: pre.sh [--dry-run|-n] [--debug|-d] [--no-spinner] [--help|-h]

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

# ==============================================================================
# Create directories
# ==============================================================================
info "Create kitty directories"

run_cmd "Create $LOCAL_APPS_DIR directory" mkdir -p "$LOCAL_APPS_DIR"
kitty_config_dir="${XDG_CONFIG_HOME:-${ZDOTDIR:-$HOME}/.config}/kitty"
run_cmd "Create $kitty_config_dir directory" mkdir -p "$kitty_config_dir"
