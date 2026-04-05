#!/usr/bin/env bash
# shellcheck shell=bash

# Shared hook helpers.
# Expected optional globals in caller:
# - DRY_RUN (0/1)
# - DEBUG (0/1)
# - USE_SPINNER (0/1)
# - LOG_DIR
# - LOG_FILE

hook_init_defaults() {
  : "${DRY_RUN:=0}"
  : "${DEBUG:=0}"
  : "${USE_SPINNER:=1}"

  if [[ ! -t 1 ]]; then
    USE_SPINNER=0
  fi

  if (( DEBUG )); then
    USE_SPINNER=0
  fi

  if [[ -n "${LOG_DIR:-}" ]]; then
    mkdir -p "$LOG_DIR"
  fi
}

log_msg() {
  local level="$1"
  shift
  if [[ -n "${LOG_FILE:-}" ]]; then
    printf '[%s] [%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$level" "$*" >> "$LOG_FILE"
  fi
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

debug_msg() {
  if (( DEBUG )); then
    log_msg DEBUG "$*"
    printf 'DEBUG: %s\n' "$*" >&2
  fi
}

log_error() {
  log_msg ERROR "$*"
}

log_failure() {
  local message="$1"
  log_msg ERROR "$message"
  if (( DEBUG )); then
    printf '[error] %s\n' "$message" >&2
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
