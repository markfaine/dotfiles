#!/usr/bin/env bash

set -euo pipefail

# ==============================================================================
# Nerd Fonts Post Hook
# ==============================================================================

INSTALL_LIST="$HOME/.config/nerdfonts/install"
FONTS_DIR_LINUX="$HOME/.local/share/fonts"
FONTS_DIR_MACOS="$HOME/Library/Fonts"
LOG_DIR="$HOME/.config/nerdfonts"
LOG_FILE="$LOG_DIR/hook-errors.log"

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
}

# Early exit if install file doesn't exist
[[ -f "$INSTALL_LIST" ]] || exit 0

# Early exit if curl/wget not available
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    log_failure "fonts hook skipped: curl and wget not available"
    exit 0
fi

# Helper to read install file, skip comments and blank lines
read_font_list() {
    grep -Ev '^\s*($|#)' "$INSTALL_LIST" 2>/dev/null || true
}

# Helper to download a font tarball
download_font() {
    local font="$1"
    local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.tar.xz"
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" RETURN

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$temp_dir/${font}.tar.xz" 2>/dev/null || return 1
    else
        wget -qO "$temp_dir/${font}.tar.xz" "$url" 2>/dev/null || return 1
    fi

    # Extract to fonts directory
    mkdir -p "$FONTS_DIR"
    tar -xf "$temp_dir/${font}.tar.xz" -C "$FONTS_DIR" || return 1

    return 0
}

# Install fonts from list
install_fonts_from_file() {
    local font
    local failed=()

    while IFS= read -r font; do
        [[ -z "$font" ]] && continue

        if ! download_font "$font"; then
            failed+=("$font")
        fi
    done < <(read_font_list)

    # Log failures if any
    if (( ${#failed[@]} > 0 )); then
        log_failure "failed to download/extract fonts: ${failed[*]}"
    fi
}

# Refresh font cache (Linux only)
refresh_font_cache() {
    if [[ "$OSTYPE" != darwin* ]] && command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f "$FONTS_DIR" >/dev/null 2>&1 || true
    fi
}

install_fonts_from_file
refresh_font_cache

