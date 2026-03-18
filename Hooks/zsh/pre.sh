#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../includes/functions.sh
source "$SCRIPT_DIR/../../includes/functions.sh"
# Common helpers from includes/functions.sh.


# ==============================================================================
# Zsh Pre Hook
# ==============================================================================

ZSH_DATA_DIR="${XDG_DATA_HOME:-${ZDOTDIR:-$HOME}/.local/share}/zsh"
SITE_FUNCTIONS_DIR="$ZSH_DATA_DIR/zsh/site-functions"
CACHE_DIR="${XDG_CACHE_HOME:-${ZDOTDIR:-$HOME}/.cache}/zsh"
LOG_DIR="${XDG_STATE_HOME:-${ZDOTDIR:-$HOME}/.local/state}"
LOG_FILE="$LOG_DIR/zsh-hook.log"

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

info "Running zsh pre hook"
if (( DRY_RUN )); then
	info "Dry-run mode enabled"
fi
if (( DEBUG )); then
	info "Debug mode enabled"
fi

# Ensure the parent directory exists
run_cmd "Create site functions parent directory" mkdir -p "$(dirname "$SITE_FUNCTIONS_DIR")"
run_cmd "Create zsh data directory" mkdir -p "$ZSH_DATA_DIR"
run_cmd "Create zsh cache directory" mkdir -p "$CACHE_DIR"

info "Zsh pre hook complete"
