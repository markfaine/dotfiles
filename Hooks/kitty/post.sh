#!/usr/bin/env bash

# This hook runs tasks after the config files have been linked

set -euo pipefail

# ==============================================================================
# Kitty Post Hook
# ==============================================================================

KITTY_APP_DIR="$HOME/.local/kitty.app"
KITTY_BIN_DIR="$KITTY_APP_DIR/bin"
KITTY_SHARE_APPS_DIR="$KITTY_APP_DIR/share/applications"
KITTY_ICON_PATH="$KITTY_APP_DIR/share/icons/hicolor/256x256/apps/kitty.png"
LOCAL_BIN_DIR="$HOME/.local/bin"
LOCAL_APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
LOG_FILE="$LOG_DIR/kitty-hook.log"

DRY_RUN=0
DEBUG=0
USE_SPINNER=1

usage() {
    cat <<'EOF'
Usage: pre.sh [--dry-run|-n] [--debug|-d] [--no-spinner] [--help|-h]

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
if [[ ! -x "$KITTY_BIN_DIR/kitty" ]]; then
  run_cmd "Link kitty binary" ln -sf "$KITTY_BIN_DIR/kitty" "$LOCAL_BIN_DIR/kitty"
fi

# Create symbolic links for kitty and kitten
if [[ ! -x "$KITTY_BIN_DIR/kitten" ]]; then
  run_cmd "Link kitten binary" ln -sf "$KITTY_BIN_DIR/kitten" "$LOCAL_BIN_DIR/kitten"
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
run_cmd "Create ~/.config" mkdir -p "$HOME/.config"
if (( DRY_RUN )); then
    info "[dry-run] Write $HOME/.config/xdg-terminals.list"
    info "          kitty.desktop"
else
    echo 'kitty.desktop' >"$HOME/.config/xdg-terminals.list"
    info "✓ Wrote $HOME/.config/xdg-terminals.list"
fi
info "xdg-terminal-exec configured."

info "Kitty setup complete."
