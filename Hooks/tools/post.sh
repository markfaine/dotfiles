#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

# ==============================================================================
# Tools Post Hook
# ==============================================================================
# Downloads and installs tools listed in the sources file.

TOOLS_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/tools/sources"
INSTALL_DIR="$HOME/.local/bin"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
LOG_FILE="$LOG_DIR/tools-hook.log"

DRY_RUN=0
DEBUG=0
USE_SPINNER=1

# ==============================================================================
# Help Message
# ==============================================================================

usage() {
	cat <<'EOF'
Usage: post.sh [--dry-run|-n] [--debug|-d] [--no-spinner] [--help|-h]

Downloads and installs tools from:
  ${XDG_CONFIG_HOME:-$HOME/.config}/tools/sources

Each line in the config should be a URL to a binary or archive.

Options:
  -n, --dry-run    Show what would be installed, but don't download/install
  -d, --debug      Verbose output; show all commands and downloads
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

# Disable spinner if not a TTY or in debug mode
if [[ ! -t 1 ]]; then
	USE_SPINNER=0
fi

if (( DEBUG )); then
	USE_SPINNER=0
fi

mkdir -p "$LOG_DIR"

# ==============================================================================
# Logging & Output Functions
# ==============================================================================

log_msg() {
	local level="$1"
	shift
	printf '[%s] [%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$level" "$*" >> "$LOG_FILE"
}

info() {
	log_msg INFO "$*"
	printf '%s\n' "$*"
}

log_error() {
	log_msg ERROR "$*"
}

debug_msg() {
	if (( DEBUG )); then
		log_msg DEBUG "$*"
		echo "DEBUG: $*" >&2
	fi
}

# Spinner for progress indication
spinner_pid=""
start_spinner() {
	if (( !USE_SPINNER )); then
		return
	fi
	(
		while true; do
			printf '\r→ '
			sleep 0.1
		done
	) &
	spinner_pid=$!
}

stop_spinner() {
	if [[ -n "$spinner_pid" ]]; then
		kill "$spinner_pid" 2>/dev/null || true
		wait "$spinner_pid" 2>/dev/null || true
		spinner_pid=""
		printf '\r✓ '
	fi
}

stop_spinner_fail() {
	if [[ -n "$spinner_pid" ]]; then
		kill "$spinner_pid" 2>/dev/null || true
		wait "$spinner_pid" 2>/dev/null || true
		spinner_pid=""
		printf '\r✗ '
	fi
}

# ==============================================================================
# Utility Functions
# ==============================================================================

# Extract filename from URL
get_filename_from_url() {
	local url="$1"
	basename "${url%\?*}"
}

# Detect archive type from filename
archive_type_for() {
	local file="$1"
	case "$file" in
		*.tar.gz)
			echo "tar.gz"
			;;
		*.tgz)
			echo "tgz"
			;;
		*.tar.bz2)
			echo "tar.bz2"
			;;
		*.tbz2)
			echo "tbz2"
			;;
		*.tar.xz)
			echo "tar.xz"
			;;
		*.txz)
			echo "txz"
			;;
		*.tar)
			echo "tar"
			;;
		*.zip)
			echo "zip"
			;;
		*)
			echo ""
			;;
	esac
}

strip_archive_extension() {
	local filename="$1"
	case "$filename" in
		*.tar.gz) printf '%s' "${filename%.tar.gz}" ;;
		*.tgz) printf '%s' "${filename%.tgz}" ;;
		*.tar.bz2) printf '%s' "${filename%.tar.bz2}" ;;
		*.tbz2) printf '%s' "${filename%.tbz2}" ;;
		*.tar.xz) printf '%s' "${filename%.tar.xz}" ;;
		*.txz) printf '%s' "${filename%.txz}" ;;
		*.tar) printf '%s' "${filename%.tar}" ;;
		*.zip) printf '%s' "${filename%.zip}" ;;
		*) printf '%s' "$filename" ;;
	esac
}

extract_archive() {
	local archive="$1"
	local archive_type="$2"
	local extract_dir="$3"
	debug_msg "Extracting $archive to $extract_dir"

	case "$archive_type" in
		tar.gz|tgz)
			tar -xzf "$archive" -C "$extract_dir"
			;;
		tar.bz2|tbz2)
			tar -xjf "$archive" -C "$extract_dir"
			;;
		tar.xz|txz)
			tar -xJf "$archive" -C "$extract_dir"
			;;
		tar)
			tar -xf "$archive" -C "$extract_dir"
			;;
		zip)
			if ! command -v unzip >/dev/null 2>&1; then
				log_error "zip archive requires unzip, but unzip is not installed"
				return 1
			fi
			unzip -oq "$archive" -d "$extract_dir"
			;;
		*)
			log_error "Unsupported archive type: $archive_type"
			return 1
			;;
	esac

	return 0
}

find_executable_in_dir() {
	local extract_dir="$1"
	local executable

	executable=$(find "$extract_dir" -type f -executable 2>/dev/null | head -1 || true)

	if [[ -z "$executable" ]]; then
		executable=$(find "$extract_dir" -type f ! -name "*.txt" ! -name "*.md" ! -name "*.LICENSE" ! -name "*.sh" 2>/dev/null | head -1 || true)
	fi

	if [[ -z "$executable" ]]; then
		log_error "No executable found in extracted archive directory: $extract_dir"
		return 1
	fi

	debug_msg "Found executable: $executable"
	echo "$executable"
	return 0
}

# ==============================================================================
# Download and Install Function
# ==============================================================================

install_utility() {
	local url="$1"
	local filename
	local archive_type
	local install_name
	local temp_dir
	local temp_file

	filename=$(get_filename_from_url "$url")
	archive_type=$(archive_type_for "$filename")
	install_name=$(strip_archive_extension "$filename")

	temp_dir=$(mktemp -d)
	temp_file="$temp_dir/$filename"

	debug_msg "Downloading: $url"

	if (( DRY_RUN )); then
		info "[dry-run] Download and install: $url"
		info "          $INSTALL_DIR/$install_name"
		rm -rf "$temp_dir"
		return 0
	fi

	start_spinner

	if ! curl -fsSL "$url" -o "$temp_file" 2>/dev/null; then
		stop_spinner_fail
		log_error "Failed to download: $url"
		echo "[✗] Failed to download: $url" >&2
		rm -rf "$temp_dir"
		return 1
	fi

	if [[ -n "$archive_type" ]]; then
		local extracted_binary
		local extract_dir
		extract_dir="$temp_dir/extracted"
		mkdir -p "$extract_dir"

		if ! extract_archive "$temp_file" "$archive_type" "$extract_dir"; then
			stop_spinner_fail
			echo "[✗] Failed to extract: $filename" >&2
			rm -rf "$temp_dir"
			return 1
		fi

		if ! extracted_binary=$(find_executable_in_dir "$extract_dir"); then
			stop_spinner_fail
			echo "[✗] Failed to extract: $filename" >&2
			rm -rf "$temp_dir"
			return 1
		fi

		if ! cp "$extracted_binary" "$INSTALL_DIR/$install_name" 2>/dev/null; then
			stop_spinner_fail
			log_error "Failed to copy extracted binary to $INSTALL_DIR/$install_name"
			echo "[✗] Failed to copy: $install_name" >&2
			rm -rf "$temp_dir"
			return 1
		fi
	else
		if ! cp "$temp_file" "$INSTALL_DIR/$install_name" 2>/dev/null; then
			stop_spinner_fail
			log_error "Failed to copy binary to $INSTALL_DIR/$install_name"
			echo "[✗] Failed to copy: $install_name" >&2
			rm -rf "$temp_dir"
			return 1
		fi
	fi

	if ! chmod +x "$INSTALL_DIR/$install_name" 2>/dev/null; then
		stop_spinner_fail
		log_error "Failed to make executable: $INSTALL_DIR/$install_name"
		echo "[✗] Failed to chmod: $install_name" >&2
		rm -rf "$temp_dir"
		return 1
	fi

	stop_spinner
	info "[✓] Installed: $install_name"
	rm -rf "$temp_dir"
	return 0
}

# ==============================================================================
# Main Script
# ==============================================================================

mkdir -p "$INSTALL_DIR" "$LOG_DIR" 2>/dev/null || true

info "Running tools post hook"
if (( DRY_RUN )); then
	info "Dry-run mode enabled"
fi
if (( DEBUG )); then
	info "Debug mode enabled"
fi

if [[ ! -f "$TOOLS_CONFIG" ]]; then
	log_error "Config file not found: $TOOLS_CONFIG"
	echo "Error: Config file not found: $TOOLS_CONFIG" >&2
	exit 1
fi

for cmd in curl tar; do
	if ! command -v "$cmd" &>/dev/null; then
		log_error "Required command not found: $cmd"
		echo "Error: Required command not found: $cmd" >&2
		exit 1
	fi
done

debug_msg "Reading tools config from: $TOOLS_CONFIG"

total=0
installed=0
failed=0

while IFS= read -r url || [[ -n "$url" ]]; do
	[[ -z "$url" || "$url" =~ ^[[:space:]]*# ]] && continue
	url=$(echo "$url" | xargs)
	((total++))

	if install_utility "$url"; then
		((installed++))
	else
		((failed++))
	fi
done < "$TOOLS_CONFIG"

info ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "Tools Installation Summary"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "Total:     $total"
info "Installed: $installed"
info "Failed:    $failed"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if (( failed > 0 )); then
	log_error "One or more tools failed to install"
	echo "Check $LOG_FILE for details on failures" >&2
	exit 1
fi

info "Tools post hook complete."

exit 0
