#!/usr/bin/env bash

set -euo pipefail

# ==============================================================================
# Zsh Post Hook
# ==============================================================================
# Validates deployed zsh dotfiles can be sourced without startup errors.

DRY_RUN=0
DEBUG=0
LOG_DIR="${XDG_STATE_HOME:-${ZDOTDIR:-$HOME}/.local/state}"
LOG_FILE="$LOG_DIR/zsh-hook.log"

usage() {
	cat <<'EOF'
Usage: post.sh [--dry-run|-n] [--debug|-d] [--help|-h]

Validate zsh startup files after deployment.

Checks performed:
  1) Ensure required files exist
  2) Syntax-check each file with zsh -n
  3) Start a login+interactive zsh shell to verify runtime sourcing

Options:
  -n, --dry-run    Print what would run
  -d, --debug      Enable verbose output
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

mkdir -p "$LOG_DIR"

log_msg() {
	local level="$1"
	shift
	printf '[%s] [%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$level" "$*" >> "$LOG_FILE"
}

info() {
	log_msg INFO "$*"
	printf '%s\n' "$*"
}

debug() {
	if (( DEBUG )); then
		log_msg DEBUG "$*"
		printf '[debug] %s\n' "$*"
	fi
}

run_cmd() {
	local description="$1"
	shift

	if (( DRY_RUN )); then
		info "[dry-run] $description"
		info "          $*"
		return 0
	fi

	if (( DEBUG )); then
		info "[run] $description"
		debug "cmd: $*"
		"$@"
		return $?
	fi

	info "$description"
	"$@" >/dev/null 2>&1
}

info "Running zsh post hook"
if (( DRY_RUN )); then
	info "Dry-run mode enabled"
fi
if (( DEBUG )); then
	info "Debug mode enabled"
fi

if ! command -v zsh >/dev/null 2>&1; then
	info "zsh not found; skipping zsh startup validation"
	exit 0
fi

required_files=("${ZDOTDIR:-$HOME}/.zshrc" "${ZDOTDIR:-$HOME}/.paths")
for file in "${required_files[@]}"; do
	if [[ ! -f "$file" ]]; then
		log_msg ERROR "required zsh startup file missing: $file"
		echo "Error: required zsh startup file missing: $file" >&2
		exit 1
	fi
done

run_cmd "Syntax check ~/.paths" zsh -n "${ZDOTDIR:-$HOME}/.paths"
run_cmd "Syntax check ~/.zshrc" zsh -n "${ZDOTDIR:-$HOME}/.zshrc"

run_cmd "Remove compiled zsh cache files" find "${ZDOTDIR:-$HOME}" -type f -name '*.zwc' -delete
run_cmd "Delete completion cache" rm -f "${ZSH_COMPDUMP:-${ZDOTDIR:-$HOME}/.zcompdump}"

# Start a login+interactive shell to match normal user startup behavior.
run_cmd "Validate login interactive zsh startup" zsh -lic 'exit 0'

info "Zsh post hook complete"
