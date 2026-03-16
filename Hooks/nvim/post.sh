#!/usr/bin/env bash

set -euo pipefail

# ==============================================================================
# Neovim Post Hook
# ==============================================================================

LOG_DIR="${XDG_STATE_HOME:-${ZDOTDIR:-$HOME}/.local/state}"
LOG_FILE="$LOG_DIR/nvim-hook.log"

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

info "Checking for Neovim..."
if ! command -v nvim >/dev/null 2>&1; then
	log_msg ERROR "Neovim not found in PATH"
    echo "Error: Neovim not found. Please install Neovim first." >&2
    exit 1
fi

# ==============================================================================
# Plugin Sync (lazy.nvim)
# ==============================================================================

info "Syncing Neovim plugins with Lazy..."
if run_cmd "Neovim lazy.nvim sync" nvim --headless -u "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua" -c 'lua require("lazy").sync()' -c 'qa!'; then
    info "Neovim plugins synced successfully."
else
	log_msg ERROR "Failed to sync Neovim plugins with lazy.nvim"
    echo "Error: Failed to sync Neovim plugins." >&2
    exit 1
fi

run_cmd "Remove compiled zsh cache files" find "${ZDOTDIR:-$HOME}" -type f -name '*.zwc' -delete
run_cmd "Delete completion cache" rm -f "${ZSH_COMPDUMP:-${ZDOTDIR:-$HOME}/.zcompdump}"

info "Neovim post hook complete."
