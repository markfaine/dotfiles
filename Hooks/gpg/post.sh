#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../includes/functions.sh
source "$SCRIPT_DIR/../../includes/functions.sh"
# Common helpers from includes/functions.sh.

# ==============================================================================
# GPG Post Hook
# ==============================================================================
# Imports GPG public keys from ~/.gnupg/*.asc into the local keyring

GPGDIR="${GNUPGHOME:-${ZDOTDIR:-$HOME}/.gnupg}"
IMPORT_DIR="${XDG_CONFIG_HOME:-${ZDOTDIR:-$HOME}/.config}/gnupg/keys"
LOG_DIR="${XDG_STATE_HOME:-${ZDOTDIR:-$HOME}/.local/state}"
LOG_FILE="$LOG_DIR/gnupg-hook.log"

DRY_RUN=0
DEBUG=0
USE_SPINNER=1

# ==============================================================================
# Help Message
# ==============================================================================

usage() {
	cat <<'EOF'
Usage: post.sh [--dry-run|-n] [--debug|-d] [--no-spinner] [--help|-h]

Imports GPG public keys (.asc files) from $IMPORT_DIR into the local keyring.

Options:
  -n, --dry-run    Show what would be imported, but don't execute
  -d, --debug      Verbose output; show all imports and details
      --no-spinner Disable spinner/progress animation
  -h, --help       Show this help message
EOF
}

# ==============================================================================
# Parse Arguments
# ==============================================================================

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
# Main Script
# ==============================================================================

# Check if gpg is available
if ! command -v gpg &>/dev/null && ! command -v gpg2 &>/dev/null; then
	log_error "gpg hook failed: gpg or gpg2 not found"
	echo "Error: gpg or gpg2 not found" >&2
	exit 1
fi

# Use gpg2 if available, otherwise gpg
GPG_CMD="gpg"
if command -v gpg2 &>/dev/null; then
	GPG_CMD="gpg2"
fi

debug_msg "Using GPG command: $GPG_CMD"
# Check if ~/.gnupg exists
"$GPG_CMD" --list-keys &>/dev/null
if [[ ! -d "$GPGDIR" ]]; then
	log_error "gpg hook failed: $GPGDIR not found"
	echo "Error: $GPGDIR not found" >&2
	exit 1
fi

# Find all .asc files in ~/.gnupg
mapfile -t asc_files < <(find -L "$IMPORT_DIR" -maxdepth 1 -name "*.asc" -type f 2>/dev/null | sort)

total=${#asc_files[@]}
imported=0
failed=0

if (( total == 0 )); then
	info "No .asc key files found in $IMPORT_DIR"
	exit 0
fi

debug_msg "Found $total .asc files to import"

# Import each key file
for key_file in "${asc_files[@]}"; do
	key_name=$(basename "$key_file")

	debug_msg "Processing: $key_file"

	if (( DRY_RUN )); then
		info "[dry-run] Import: $key_name"
		((imported++))
		continue
	fi

	start_spinner

	# Import the key
	if $GPG_CMD --import "$key_file" >/dev/null 2>&1; then
		stop_spinner
		info "[✓] Imported: $key_name"
		((imported++))
	else
		stop_spinner_fail
		log_error "Failed to import: $key_file"
		echo "[✗] Failed to import: $key_name" >&2
		((failed++))
	fi
done

# Summary
info ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "GPG Key Import Summary"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "Total:     $total"
info "Imported:  $imported"
info "Failed:    $failed"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if (( failed > 0 )); then
	echo "Check $LOG_FILE for details on failures" >&2
	exit 1
fi

exit 0
