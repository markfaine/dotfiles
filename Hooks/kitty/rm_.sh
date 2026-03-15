#!/usr/bin/env bash

# This hook removes any generated files and directories when
# the 'tuckr unset' command runs.

set -euo pipefail

# ==============================================================================
# Kitty Clean Hook
# ==============================================================================

KITTY_APP_DIR="${ZDOTDIR:-$HOME}/.local/kitty.app"
LOG_DIR="${XDG_STATE_HOME:-${ZDOTDIR:-$HOME}/.local/state}"
LOG_FILE="$LOG_DIR/kitty-clean-hook.log"
LOCAL_BIN_DIR="${ZDOTDIR:-$HOME}/.local/bin"
LOCAL_APPS_DIR="${XDG_DATA_HOME:-${ZDOTDIR:-$HOME}/.local/share}/applications"

DRY_RUN=0
DEBUG=0
USE_SPINNER=1

usage() {
    cat <<'EOF'
Usage: rm_.sh [--dry-run|-n] [--debug|-d] [--no-spinner] [--help|-h]

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

# ==============================================================================
# Remove directories and symlinks
# ==============================================================================
info "Remove kitty directories and symlinks"
kitty_config_dir="${XDG_CONFIG_HOME:-${ZDOTDIR:-$HOME}/.config}/kitty"
xdg_config_dir="${XDG_CONFIG_HOME:-${ZDOTDIR:-$HOME}/.config}"
run_cmd "Remove $kitty_config_dir directory" rm -rf "$kitty_config_dir"
run_cmd "Remove $KITTY_APP_DIR directory" rm -rf "$KITTY_APP_DIR"
run_cmd "Remove $LOG_FILE" rm -f "$LOG_FILE"
run_cmd "Remove kitty binary symlink" rm -f "$LOCAL_BIN_DIR/kitty"
run_cmd "Remove kitten binary symlink" rm -f "$LOCAL_BIN_DIR/kitten"
run_cmd "Remove kitty desktop file" rm -f "$LOCAL_APPS_DIR/kitty.desktop"
run_cmd "Remove kitty-open desktop file" rm -f "$LOCAL_APPS_DIR/kitty-open.desktop"
run_cmd "Remove xdg-terminals list" rm -f "$xdg_config_dir/xdg-terminals.list"

run_cmd "Remove compiled zsh cache files" find "${ZDOTDIR:-$HOME}" -type f -name '*.zwc' -delete
run_cmd "Delete completion cache" rm -f "${ZSH_COMPDUMP:-${ZDOTDIR:-$HOME}/.zcompdump}"

