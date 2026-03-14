#!/usr/bin/env bash

set -euo pipefail

# ==============================================================================
# Fonts Post Hook
# ==============================================================================

INSTALL_LIST="$HOME/.fontlist"
FONTS_DIR_LINUX="$HOME/.local/share/fonts"
FONTS_DIR_MACOS="$HOME/Library/Fonts"
LOG_DIR="$HOME/.local/var/log"
LOG_FILE="$LOG_DIR/fonts-hook-errors.log"

DRY_RUN=0
DEBUG=0
USE_SPINNER=1

usage() {
    cat <<'EOF'
Usage: post.sh [--dry-run|-n] [--debug|-d] [--no-spinner] [--help|-h]

Install fonts listed in ~/.fontlist.

Each non-comment line in ~/.fontlist must be a downloadable font archive URL.

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

# Detect platform and set fonts directory
if [[ "$OSTYPE" == darwin* ]]; then
    FONTS_DIR="$FONTS_DIR_MACOS"
else
    FONTS_DIR="$FONTS_DIR_LINUX"
fi

# Helper function to log failures
log_failure() {
    local message="$1"
    mkdir -p "$LOG_DIR"
    printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$message" >> "$LOG_FILE"
	if (( DEBUG )); then
		printf '[error] %s\n' "$message" >&2
	fi
}

# Early exit if install file doesn't exist
if [[ ! -f "$INSTALL_LIST" ]]; then
    info "No font install list at $INSTALL_LIST"
    exit 0
fi

# Early exit if curl/wget not available
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    log_failure "fonts hook skipped: curl and wget not available"
    exit 0
fi

# Helper to read install file, skip comments and blank lines
read_font_list() {
    grep -Ev '^\s*($|#)' "$INSTALL_LIST" 2>/dev/null || true
}

# Build a readable label from the font list entry.
font_label() {
    local entry="$1"

    basename "${entry%%\?*}"
}

# Pick a local archive filename from the resolved URL.
archive_filename() {
    local url="$1"
    local filename

    filename=$(basename "${url%%\?*}")
    if [[ -z "$filename" || "$filename" == "/" ]]; then
        filename="font-archive.tar.xz"
    fi

    printf '%s' "$filename"
}

# Extract supported archive formats into the fonts directory.
extract_font_archive() {
    local archive_path="$1"
    local label="$2"

    case "$archive_path" in
        *.tar.xz|*.txz)
            run_cmd "Extract $label" tar -xJf "$archive_path" -C "$FONTS_DIR"
            ;;
        *.tar.gz|*.tgz)
            run_cmd "Extract $label" tar -xzf "$archive_path" -C "$FONTS_DIR"
            ;;
        *.tar)
            run_cmd "Extract $label" tar -xf "$archive_path" -C "$FONTS_DIR"
            ;;
        *.zip)
            if ! command -v unzip >/dev/null 2>&1; then
                log_failure "fonts hook skipped zip archive for $label: unzip not available"
                return 1
            fi
            run_cmd "Extract $label" unzip -oq "$archive_path" -d "$FONTS_DIR"
            ;;
        *)
            log_failure "unsupported font archive format for $label: $archive_path"
            return 1
            ;;
    esac
}

# Helper to download and extract a font archive.
download_font() {
    local entry="$1"
    local url="$1"
    local label
    local filename
    local temp_dir

    if [[ ! "$url" =~ ^https?:// ]]; then
        log_failure "invalid font entry in $INSTALL_LIST: $entry"
        return 1
    fi

    label=$(font_label "$entry")
    filename=$(archive_filename "$url")

	if (( DRY_RUN )); then
		info "[dry-run] Download and extract font: $label"
		info "          $url -> $FONTS_DIR"
		return 0
	fi

    temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" RETURN

    if command -v curl >/dev/null 2>&1; then
		if ! run_cmd "Download $label" curl -fsSL "$url" -o "$temp_dir/$filename"; then
			return 1
		fi
    else
		if ! run_cmd "Download $label" wget -qO "$temp_dir/$filename" "$url"; then
			return 1
		fi
    fi

    # Extract to fonts directory
	run_cmd "Create fonts directory" mkdir -p "$FONTS_DIR"
	extract_font_archive "$temp_dir/$filename" "$label" || return 1

    return 0
}

# Install fonts from list
install_fonts_from_file() {
    local font_entry
    local failed=()
	local attempted=0

    while IFS= read -r font_entry; do
        [[ -z "$font_entry" ]] && continue
		attempted=$((attempted + 1))
		info "Processing font: $(font_label "$font_entry")"

        if ! download_font "$font_entry"; then
			failed+=("$font_entry")
        fi
    done < <(read_font_list)

	if (( attempted == 0 )); then
		info "No fonts listed for installation"
	fi

    # Log failures if any
    if (( ${#failed[@]} > 0 )); then
        log_failure "failed to download/extract fonts: ${failed[*]}"
		info "Some fonts failed: ${failed[*]}"
	else
		info "Font install step complete"
    fi
}

# Refresh font cache (Linux only)
refresh_font_cache() {
    if [[ "$OSTYPE" != darwin* ]] && command -v fc-cache >/dev/null 2>&1; then
		run_cmd "Refresh font cache" fc-cache -f "$FONTS_DIR" || true
    fi
}

info "Running fonts post hook"
if (( DRY_RUN )); then
	info "Dry-run mode enabled"
fi
if (( DEBUG )); then
	info "Debug mode enabled"
fi

install_fonts_from_file
refresh_font_cache

info "Fonts post hook complete"
