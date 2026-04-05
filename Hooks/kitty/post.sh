#!/usr/bin/env bash

# This hook runs tasks after the config files have been linked

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../includes/functions.sh
source "$SCRIPT_DIR/../../includes/functions.sh"
# Common helpers from includes/functions.sh.


# ==============================================================================
# Kitty Post Hook
# ==============================================================================

KITTY_APP_DIR="${ZDOTDIR:-$HOME}/.local/kitty.app"
KITTY_BIN_DIR="$KITTY_APP_DIR/bin"
KITTY_SHARE_APPS_DIR="$KITTY_APP_DIR/share/applications"
KITTY_ICON_PATH="$KITTY_APP_DIR/share/icons/hicolor/256x256/apps/kitty.png"
LOCAL_BIN_DIR="${ZDOTDIR:-$HOME}/.local/bin"
LOCAL_APPS_DIR="${XDG_DATA_HOME:-${ZDOTDIR:-$HOME}/.local/share}/applications"
LOG_DIR="${XDG_STATE_HOME:-${ZDOTDIR:-$HOME}/.local/state}"
LOG_FILE="$LOG_DIR/kitty-hook.log"

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

hook_init_defaults

# ==============================================================================
# Install Kitty
# ==============================================================================
info "Checking if Kitty is already installed..."
if [[ -x "$KITTY_BIN_DIR/kitty" ]]; then
    info "Kitty is already installed. Skipping installation."
else
    info "Installing Kitty..."

    # Create parent directories
    mkdir -p "$KITTY_BIN_DIR"
    mkdir -p "$KITTY_SHARE_APPS_DIR"
    mkdir -p "$(dirname "$KITTY_ICON_PATH")"
    mkdir -p "$LOCAL_BIN_DIR"
    mkdir -p "$LOCAL_APPS_DIR"

    if ! command -v curl >/dev/null 2>&1; then
        echo "Error: curl is required to install Kitty." >&2
        exit 1
    fi
    if ! command -v xz >/dev/null 2>&1; then
        echo "Error: xz is required to install Kitty." >&2
        exit 1
    fi
	if ! run_cmd "Download and run Kitty installer" bash -c 'curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin'; then
        echo "Error: Failed to install Kitty." >&2
        exit 1
    fi
    info "Kitty installed successfully."
fi

# ==============================================================================
# Desktop Integration
# ==============================================================================

info "Setting up symbolic links for Kitty..."
run_cmd "Create local bin directory" mkdir -p "$LOCAL_BIN_DIR"

# Create symbolic links for kitty and kitten
if [[ -x "$KITTY_BIN_DIR/kitty" ]]; then
        run_cmd "Link kitty binary" ln -sf "$KITTY_BIN_DIR/kitty" "$LOCAL_BIN_DIR/kitty"
else
        info "Kitty binary missing at $KITTY_BIN_DIR/kitty; skipping symlink"
fi

# Create symbolic links for kitty and kitten
if [[ -x "$KITTY_BIN_DIR/kitten" ]]; then
        run_cmd "Link kitten binary" ln -sf "$KITTY_BIN_DIR/kitten" "$LOCAL_BIN_DIR/kitten"
else
        info "Kitten binary missing at $KITTY_BIN_DIR/kitten; skipping symlink"
fi

info "Copying desktop files..."
run_cmd "Create local applications directory" mkdir -p "$LOCAL_APPS_DIR"
run_cmd "Copy kitty.desktop" cp "$KITTY_SHARE_APPS_DIR/kitty.desktop" "$LOCAL_APPS_DIR/"

if [[ -f "$KITTY_SHARE_APPS_DIR/kitty-open.desktop" ]]; then
    run_cmd "Copy kitty-open.desktop" cp "$KITTY_SHARE_APPS_DIR/kitty-open.desktop" "$LOCAL_APPS_DIR/"
fi

info "Updating desktop file paths..."
run_cmd "Patch desktop icon path" sed -i "s|Icon=kitty|Icon=$KITTY_ICON_PATH|g" "$LOCAL_APPS_DIR"/kitty*.desktop
run_cmd "Patch desktop exec path" sed -i "s|Exec=kitty|Exec=$KITTY_BIN_DIR/kitty|g" "$LOCAL_APPS_DIR"/kitty*.desktop
info "Desktop files updated."

info "Setting up xdg-terminal-exec..."
XDG_CONFIG_DIR="${XDG_CONFIG_HOME:-${ZDOTDIR:-$HOME}/.config}"
run_cmd "Create $XDG_CONFIG_DIR" mkdir -p "$XDG_CONFIG_DIR"
if (( DRY_RUN )); then
    info "[dry-run] Write $XDG_CONFIG_DIR/xdg-terminals.list"
    info "          kitty.desktop"
else
    echo 'kitty.desktop' >"$XDG_CONFIG_DIR/xdg-terminals.list"
    info "✓ Wrote $XDG_CONFIG_DIR/xdg-terminals.list"
fi
info "xdg-terminal-exec configured."

run_cmd "Remove compiled zsh cache files" find "${ZDOTDIR:-$HOME}" -type f -name '*.zwc' -delete
run_cmd "Delete completion cache" rm -f "${ZSH_COMPDUMP:-${ZDOTDIR:-$HOME}/.zcompdump}"

info "Kitty setup complete."
