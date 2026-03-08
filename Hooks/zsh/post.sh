#!/usr/bin/env bash

set -euo pipefail

# ==============================================================================
# Zsh Post Hook (Template)
# ==============================================================================

DRY_RUN=0
DEBUG=0

usage() {
	cat <<'EOF'
Usage: post.sh [--dry-run|-n] [--debug|-d] [--help|-h]

Template hook for zsh-specific post-deploy actions.
Currently performs no system changes.

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

info() {
	printf '%s\n' "$*"
}

debug() {
	if (( DEBUG )); then
		printf '[debug] %s\n' "$*"
	fi
}

run_step() {
	local description="$1"

	if (( DRY_RUN )); then
		info "[dry-run] $description"
		return 0
	fi

	info "$description"
}

info "Running zsh post hook (template)"
if (( DRY_RUN )); then
	info "Dry-run mode enabled"
fi
if (( DEBUG )); then
	info "Debug mode enabled"
fi

# Placeholder tasks (to be implemented once requirements are defined):
# run_step "Validate zsh plugins are available"
# run_step "Precompile zsh scripts"
# run_step "Migrate legacy zsh local config"
debug "No zsh post-deploy tasks defined yet"

info "Zsh post hook complete (no-op template)"



