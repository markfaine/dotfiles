#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

# ==============================================================================
# Tools Post Hook
# ==============================================================================
# Downloads and installs tools from ~/.config/tools/.config/tools/config
# that are not available via mise. Supports both binary files and archives.

TOOLS_CONFIG="$HOME/.tools"
INSTALL_DIR="$HOME/.local/bin"
LOG_DIR="$HOME/.local/var/log"
LOG_FILE="$LOG_DIR/tools-hook-errors.log"

DRY_RUN=0
DEBUG=0
USE_SPINNER=1

# ==============================================================================
# Help Message
# ==============================================================================

usage() {
	cat <<'EOF'
Usage: post.sh [--dry-run|-n] [--debug|-d] [--no-spinner] [--help|-h]

Downloads and installs tools from config that aren't available via mise.
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

# ==============================================================================
# Logging & Output Functions
# ==============================================================================

log_error() {
	{
		printf '%s: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
	} >> "$LOG_FILE" 2>&1
}

debug_msg() {
	if (( DEBUG )); then
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

# Detect if file is an archive
is_archive() {
	local file="$1"
	case "$file" in
		*.tar.gz|*.tgz)
			echo "tar.gz"
			;;
		*.tar.bz2|*.tbz2)
			echo "tar.bz2"
			;;
		*.tar.xz|*.txz)
			echo "tar.xz"
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

# Extract archive and find the executable
extract_and_find_binary() {
	local archive="$1"
	local archive_type="$2"
	local extract_dir
	extract_dir=$(mktemp -d)
	debug_msg "Extracting $archive to $extract_dir"

	case "$archive_type" in
		tar.gz|tgz)
			tar -xzf "$archive" -C "$extract_dir" 2>/dev/null || {
				log_error "Failed to extract $archive (tar.gz)"
				rm -rf "$extract_dir"
				return 1
			}
			;;
		tar.bz2|tbz2)
			tar -xjf "$archive" -C "$extract_dir" 2>/dev/null || {
				log_error "Failed to extract $archive (tar.bz2)"
				rm -rf "$extract_dir"
				return 1
			}
			;;
		tar.xz|txz)
			tar -xJf "$archive" -C "$extract_dir" 2>/dev/null || {
				log_error "Failed to extract $archive (tar.xz)"
				rm -rf "$extract_dir"
				return 1
			}
			;;
		tar)
			tar -xf "$archive" -C "$extract_dir" 2>/dev/null || {
				log_error "Failed to extract $archive (tar)"
				rm -rf "$extract_dir"
				return 1
			}
			;;
		zip)
			unzip -q "$archive" -d "$extract_dir" 2>/dev/null || {
				log_error "Failed to extract $archive (zip)"
				rm -rf "$extract_dir"
				return 1
			}
			;;
	esac

	# Find the first executable in the extracted directory
	local executable
	executable=$(find "$extract_dir" -type f -executable 2>/dev/null | head -1)

	if [[ -z "$executable" ]]; then
		executable=$(find "$extract_dir" -type f ! -name "*.txt" ! -name "*.md" ! -name "*.LICENSE" ! -name "*.sh" 2>/dev/null | head -1)
	fi

	if [[ -z "$executable" ]]; then
		log_error "No executable found in extracted archive: $archive"
		rm -rf "$extract_dir"
		return 1
	fi

	echo "$executable"
	debug_msg "Found executable: $executable"
}

# ==============================================================================
# Download and Install Function
# ==============================================================================

install_utility() {
	local url="$1"
	local filename
	local archive_type
	local temp_file
	local install_name

	filename=$(get_filename_from_url "$url")
	archive_type=$(is_archive "$filename")

	temp_file=$(mktemp)
	trap "rm -f $temp_file" RETURN

	debug_msg "Downloading: $url"

	if [[ -n "$archive_type" ]]; then
		install_name="${filename%.*}"
		[[ "$install_name" == *.tar ]] && install_name="${install_name%.*}"
	else
		install_name="$filename"
	fi

	if (( DRY_RUN )); then
		debug_msg "[DRY-RUN] Would download: $url → $INSTALL_DIR/$install_name"
		echo "[DRY-RUN] Download: $url → $INSTALL_DIR/$install_name"
		return 0
	fi

	start_spinner

	if ! curl -fsSL "$url" -o "$temp_file" 2>/dev/null; then
		stop_spinner_fail
		log_error "Failed to download: $url"
		echo "[✗] Failed to download: $url" >&2
		return 1
	fi

	if [[ -n "$archive_type" ]]; then
		local extracted_binary
		if ! extracted_binary=$(extract_and_find_binary "$temp_file" "$archive_type"); then
			stop_spinner_fail
			echo "[✗] Failed to extract: $filename" >&2
			return 1
		fi

		if ! cp "$extracted_binary" "$INSTALL_DIR/$install_name" 2>/dev/null; then
			stop_spinner_fail
			log_error "Failed to copy extracted binary to $INSTALL_DIR/$install_name"
			echo "[✗] Failed to copy: $install_name" >&2
			return 1
		fi

		local extract_dir
		extract_dir=$(dirname "$extracted_binary")
		rm -rf "$extract_dir" 2>/dev/null || true
	else
		if ! cp "$temp_file" "$INSTALL_DIR/$install_name" 2>/dev/null; then
			stop_spinner_fail
			log_error "Failed to copy binary to $INSTALL_DIR/$install_name"
			echo "[✗] Failed to copy: $install_name" >&2
			return 1
		fi
	fi

	if ! chmod +x "$INSTALL_DIR/$install_name" 2>/dev/null; then
		stop_spinner_fail
		log_error "Failed to make executable: $INSTALL_DIR/$install_name"
		echo "[✗] Failed to chmod: $install_name" >&2
		return 1
	fi

	stop_spinner
	echo "[✓] Installed: $install_name"
	return 0
}

# ==============================================================================
# Main Script
# ==============================================================================

mkdir -p "$INSTALL_DIR" "$LOG_DIR" 2>/dev/null || true

if [[ ! -f "$TOOLS_CONFIG" ]]; then
	echo "Error: Config file not found: $TOOLS_CONFIG" >&2
	exit 1
fi

for cmd in curl tar unzip; do
	if ! command -v "$cmd" &>/dev/null; then
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

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Tools Installation Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total:     $total"
echo "Installed: $installed"
echo "Failed:    $failed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if (( failed > 0 )); then
	echo "Check $LOG_FILE for details on failures" >&2
	exit 1
fi

exit 0
