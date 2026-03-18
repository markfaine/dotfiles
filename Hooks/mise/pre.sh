#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../includes/functions.sh
source "$SCRIPT_DIR/../../includes/functions.sh"
# Common helpers from includes/functions.sh.


# ==============================================================================
# Mise Pre Hook
# ==============================================================================
# Install mise if missing, without modifying shell rc files.

MISE_BIN="${ZDOTDIR:-$HOME}/.local/bin/mise"
LOG_DIR="${XDG_STATE_HOME:-${ZDOTDIR:-$HOME}/.local/state}"
LOG_FILE="$LOG_DIR/mise-pre-hook.log"

DRY_RUN=0
DEBUG=0
USE_SPINNER=1

usage() {
	cat <<'EOF'
Usage: pre.sh [--dry-run|-n] [--debug|-d] [--no-spinner] [--help|-h]

Options:
  -n, --dry-run    Show what would run, but do not execute commands
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

if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
	echo "Error: curl or wget is required to install mise." >&2
	exit 1
fi

if [[ -x "$MISE_BIN" ]]; then
	info "Mise already installed at $MISE_BIN"
	exit 0
fi

info "Installing mise..."

info "Create parent directories"
local_bin_dir="$(dirname "$MISE_BIN")"
mise_config_dir="${XDG_CONFIG_HOME:-${ZDOTDIR:-$HOME}/.config}/mise"
run_cmd "Create $local_bin_dir directory" mkdir -p "$local_bin_dir"
run_cmd "Create $mise_config_dir directory" mkdir -p "$mise_config_dir"

if command -v curl >/dev/null 2>&1; then
	run_cmd "Install mise via https://mise.run" bash -c 'curl https://mise.run | sh'
else
	run_cmd "Install mise via https://mise.run" bash -c 'wget -qO- https://mise.run | sh'
fi

if [[ -x "$MISE_BIN" ]]; then
	info "Mise install complete: $MISE_BIN"
else
	echo "Error: mise installation did not produce $MISE_BIN" >&2
	exit 1
fi
