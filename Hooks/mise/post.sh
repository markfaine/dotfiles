#!/usr/bin/env bash

set -euo pipefail

# ==============================================================================
# Mise Post Hook
# ==============================================================================
# Ensure dependency ordering after dotfiles are deployed:
#   1) bootstrap Node first
#   2) install full mise toolchain (including npm:* tools)

MISE_BIN="$HOME/.local/bin/mise"

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

if [[ ! -t 1 ]]; then
	USE_SPINNER=0
fi

if (( DEBUG )); then
	USE_SPINNER=0
fi

info() {
	printf '%s\n' "$*"
}

debug() {
	if (( DEBUG )); then
		printf '[debug] %s\n' "$*"
	fi
}

run_cmd() {
	local label="$1"
	shift

	if (( DRY_RUN )); then
		info "[dry-run] $label"
		info "          $*"
		return 0
	fi

	if (( DEBUG )); then
		info "[run] $label"
		debug "cmd: $*"
		"$@"
		return $?
	fi

	if (( USE_SPINNER )); then
		local spinner='|/-\\'
		local idx=0
		local pid
		local status=0

		printf '→ %s ' "$label"
		"$@" >/dev/null 2>&1 &
		pid=$!

		while kill -0 "$pid" 2>/dev/null; do
			printf '\r→ %s [%c]' "$label" "${spinner:idx++%4:1}"
			sleep 0.15
		done

		if ! wait "$pid"; then
			status=$?
		fi

		if (( status == 0 )); then
			printf '\r✓ %s\n' "$label"
		else
			printf '\r✗ %s\n' "$label"
		fi

		return $status
	fi

	printf '→ %s\n' "$label"
	if "$@" >/dev/null 2>&1; then
		printf '✓ %s\n' "$label"
		return 0
	fi
	printf '✗ %s\n' "$label"
	return 1
}

if [[ ! -x "$MISE_BIN" ]]; then
	info "Mise not installed yet. Skipping Node bootstrap."
	exit 0
fi

# 1. Force the correct backend immediately
run_cmd "Setting node backend to core" "$MISE_BIN" settings set preferred_backends node=core

# 2. Clear corrupted cache
run_cmd "Cleaning mise cache" rm -rf "$HOME/.cache/mise"

# 3. BOOTSTRAP NODE FIRST
# This is the "secret sauce." Installing node standalone ensures
# it's ready before mise tries to process the "npm:*" keys.
run_cmd "Bootstrapping Node.js runtime" "$MISE_BIN" install node@latest

# 4. PRE-FLIGHT CHECK (Optional but helpful)
if ! "$MISE_BIN" run node -- node -v >/dev/null 2>&1; then
    info "✗ Node bootstrap failed (likely missing libatomic1). Check logs."
    exit 1
fi

# 5. RUN FULL INSTALL
# Now that Node is present, the npm:* tools will install smoothly.
run_cmd "Installing remaining toolchain" "$MISE_BIN" install --yes

# 6. POST-INSTALL MAINTENANCE
run_cmd "Pruning stale tools" "$MISE_BIN" prune --tools --yes
run_cmd "Rebuilding shims" "$MISE_BIN" reshim

# 7. RESTORE SETTINGS
run_cmd "Enabling experimental features" "$MISE_BIN" settings set experimental true
run_cmd "Enabling lockfile" "$MISE_BIN" settings set lockfile true

info "Mise toolchain install complete."
