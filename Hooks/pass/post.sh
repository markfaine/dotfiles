#!/usr/bin/env bash

set -euo pipefail

# ==============================================================================
# Pass Post Hook
# ==============================================================================

REPOS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/pass/repos"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
LOG_FILE="$LOG_DIR/pass-hook.log"
PASS_INIT_ENTRY="docker-credential-helpers/docker-pass-initialized-check"
PASS_INIT_VALUE="pass is initialized"

DRY_RUN=0
DEBUG=0
USE_SPINNER=1

usage() {
	cat <<'EOF'
Usage: post.sh [--dry-run|-n] [--debug|-d] [--no-spinner] [--help|-h]

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

if [[ ! -t 1 ]]; then
	USE_SPINNER=0
fi

if (( DEBUG )); then
	USE_SPINNER=0
fi

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
			log_msg ERROR "$label failed: $*"
		fi

		return $status
	fi

	printf '→ %s\n' "$label"
	if "$@" >/dev/null 2>&1; then
		printf '✓ %s\n' "$label"
		return 0
	fi
	printf '✗ %s\n' "$label"
	log_msg ERROR "$label failed: $*"
	return 1
}

read_repo_list() {
	grep -Ev '^\s*($|#)' "$REPOS_FILE" 2>/dev/null || true
}

clone_repo_if_missing() {
	local repo_url="$1"
	local relative_target="$2"
	local target_dir="${ZDOTDIR:-$HOME}/$relative_target"

	if [[ -d "$target_dir/.git" || -d "$target_dir" ]]; then
		info "Repo target already exists: $target_dir"
		return 0
	fi

	run_cmd "Clone $(basename "$relative_target")" git clone "$repo_url" "$target_dir"
}

ensure_pass_initialized_marker() {
	if ! command -v pass >/dev/null 2>&1; then
		log_msg ERROR "pass command not found; cannot verify initialization marker"
		info "pass command not found. Skipping initialization marker setup."
		return 0
	fi

	local existing_value=""
	if existing_value=$(pass show "$PASS_INIT_ENTRY" 2>/dev/null); then
		if [[ "$existing_value" == "$PASS_INIT_VALUE" ]]; then
			info "Pass initialization marker already present."
			return 0
		fi
	fi

	if (( DRY_RUN )); then
		info "[dry-run] Initialize pass marker"
		info "          pass insert -m $PASS_INIT_ENTRY"
		return 0
	fi

	if printf '%s\n' "$PASS_INIT_VALUE" | pass insert -m -f "$PASS_INIT_ENTRY" >/dev/null 2>&1; then
		info "Pass initialization marker created."
	else
		log_msg ERROR "Failed to create pass initialization marker: $PASS_INIT_ENTRY"
		return 1
	fi
}

info "Running pass post hook"
if (( DRY_RUN )); then
	info "Dry-run mode enabled"
fi
if (( DEBUG )); then
	info "Debug mode enabled"
fi

if [[ ! -f "$REPOS_FILE" ]]; then
	info "No repo list found at $REPOS_FILE"
	exit 0
fi

if ! command -v git >/dev/null 2>&1; then
	log_msg ERROR "git command not found; cannot clone pass repositories"
	echo "Error: git not found" >&2
	exit 1
fi

while IFS=',' read -r repo_url relative_target; do
	[[ -z "$repo_url" || -z "$relative_target" ]] && continue
	clone_repo_if_missing "$repo_url" "$relative_target"
done < <(read_repo_list)

ensure_pass_initialized_marker

info "Pass post hook complete"
