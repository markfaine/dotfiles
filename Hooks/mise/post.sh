#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../includes/functions.sh
source "$SCRIPT_DIR/../../includes/functions.sh"
# Common helpers from includes/functions.sh.


# ==============================================================================
# Mise Post Hook
# ==============================================================================
# Ensure dependency ordering after dotfiles are deployed:
#   1) bootstrap Node first
#   2) other misc. tasks to ensure a clean environment

MISE_BIN="${ZDOTDIR:-$HOME}/.local/bin/mise"
LOG_DIR="${XDG_STATE_HOME:-${ZDOTDIR:-$HOME}/.local/state}"
LOG_FILE="$LOG_DIR/mise-post-hook.log"

DRY_RUN=0
DEBUG=0
USE_SPINNER=1

usage() {
	cat <<'EOF'
Usage: post.sh [--dry-run|-n] [--debug|-d] [--no-spinner] [--help|-h]

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

if [[ ! -x "$MISE_BIN" ]]; then
	info "Mise not installed yet. Skipping Node bootstrap."
	exit 0
fi

# Ensure Node is available before installing npm:* tools.
run_cmd "Bootstrap Node via mise" "$MISE_BIN" exec -y --silent node@latest -- node -v

# Install configured toolchain under node-enabled context.
#run_cmd "Install all configured mise tools" "$MISE_BIN" exec -y --silent node@latest -- "$MISE_BIN" install

# Refresh command shims and prune stale installs.
run_cmd "Rebuild mise shims" "$MISE_BIN" reshim
run_cmd "Prune unused mise tool versions" "$MISE_BIN" prune --tools --yes

run_cmd "Remove compiled zsh cache files" find "${ZDOTDIR:-$HOME}" -type f -name '*.zwc' -delete
run_cmd "Delete completion cache" rm -f "${ZSH_COMPDUMP:-${ZDOTDIR:-$HOME}/.zcompdump}"

info "Mise post hook complete."
