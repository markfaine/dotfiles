#!/usr/bin/env bash

# This hook ensures the required directory structure for creating symlinks

set -euo pipefail

# ==============================================================================
# Kitty Pre Hook
# ==============================================================================

LOCAL_APPS_DIR="${XDG_DATA_HOME:-${ZDOTDIR:-$HOME}/.local/share}/applications"
LOG_DIR="${XDG_STATE_HOME:-${ZDOTDIR:-$HOME}/.local/state}"
LOG_FILE="$LOG_DIR/kitty-pre-hook.log"

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
# Create directories
# ==============================================================================
info "Create kitty directories"

run_cmd "Create $LOCAL_APPS_DIR directory" mkdir -p "$LOCAL_APPS_DIR"
kitty_config_dir="${XDG_CONFIG_HOME:-${ZDOTDIR:-$HOME}/.config}/kitty"
run_cmd "Create $kitty_config_dir directory" mkdir -p "$kitty_config_dir"
