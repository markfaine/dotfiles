#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

# ==============================================================================
# SSH Post Hook
# ==============================================================================
# Downloads SSH public keys from URLs and adds them to ~/.ssh/authorized_keys
# Prevents duplicate keys while allowing unique keys to be appended

SSH_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ssh/authorized_keys"
SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
LOG_FILE="$LOG_DIR/ssh-hook.log"

DRY_RUN=0
DEBUG=0
USE_SPINNER=1

# ==============================================================================
# Help Message
# ==============================================================================

usage() {
  cat <<'EOF'
Usage: post.sh [--dry-run|-n] [--debug|-d] [--no-spinner] [--help|-h]

Downloads SSH public keys from URLs in ~/.config/ssh/authorized_keys and adds them to
~/.ssh/authorized_keys. Prevents duplicates while allowing unique keys.

Options:
  -n, --dry-run    Show what would be added, but don't modify authorized_keys
  -d, --debug      Verbose output; show all downloads and modifications
      --no-spinner Disable spinner/progress animation
  -h, --help       Show this help message
EOF
}

# ==============================================================================
# Parse Arguments
# ==============================================================================

for arg in "$@"; do
  case "$arg" in
  -n | --dry-run)
    DRY_RUN=1
    ;;
  -d | --debug)
    DEBUG=1
    ;;
  --no-spinner)
    USE_SPINNER=0
    ;;
  -h | --help)
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

if ((DEBUG)); then
  USE_SPINNER=0
fi

mkdir -p "$LOG_DIR"

# ==============================================================================
# Logging & Output Functions
# ==============================================================================

log_msg() {
  local level="$1"
  shift
  printf '[%s] [%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$level" "$*" >>"$LOG_FILE"
}

info() {
  log_msg INFO "$*"
  printf '%s\n' "$*"
}

log_error() {
  log_msg ERROR "$*"
}

debug_msg() {
  if ((DEBUG)); then
    log_msg DEBUG "$*"
    echo "DEBUG: $*" >&2
  fi
}

# Spinner for progress indication
spinner_pid=""
start_spinner() {
  if ((!USE_SPINNER)); then
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

# Get fingerprint/hash of a key for deduplication
get_key_fingerprint() {
  local key="$1"
  # Get the key components (skip comment if present)
  echo "$key" | awk '{print $1, $2}' | sha256sum | awk '{print $1}'
}

# Check if key already exists in authorized_keys
key_exists() {
  local fingerprint="$1"
  if [[ ! -f "$AUTHORIZED_KEYS" ]]; then
    return 1
  fi
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    local line_fp
    line_fp=$(get_key_fingerprint "$line")
    if [[ "$line_fp" == "$fingerprint" ]]; then
      return 0
    fi
  done <"$AUTHORIZED_KEYS"
  return 1
}

# Download key from URL
download_key() {
  local url="$1"
  local temp_file
  temp_file=$(mktemp)
	# shellcheck disable=SC2064
	trap "rm -f $temp_file" RETURN

  debug_msg "Downloading: $url"

  if ! curl -fsSL "$url" -o "$temp_file" 2>/dev/null; then
    return 1
  fi

  # Verify it looks like an SSH public key
  if ! grep -q "^ssh-" "$temp_file" 2>/dev/null; then
    debug_msg "Downloaded file doesn't appear to be a valid SSH public key: $url"
    return 1
  fi

  cat "$temp_file"
  return 0
}

# Add key to authorized_keys
add_key_to_authorized_keys() {
  local key="$1"
  local url_source="$2"

  # Verify it's a valid key format
  if ! echo "$key" | grep -q "^ssh-" 2>/dev/null; then
    log_error "Invalid SSH key format from $url_source"
    return 1
  fi

  # Get fingerprint for deduplication
  local fingerprint
  fingerprint=$(get_key_fingerprint "$key")

  # Check if key already exists
  if key_exists "$fingerprint"; then
    debug_msg "Key already exists in authorized_keys (from $url_source)"
    return 2 # Indicate key already exists (not an error, but not new)
  fi

  # Create ~/.ssh if needed
  mkdir -p "$SSH_DIR" 2>/dev/null || true

  # Append to authorized_keys
  {
    # Add comment with source URL
    echo "# Added from: $url_source"
    echo "$key"
  } >>"$AUTHORIZED_KEYS"

  return 0
}

# ==============================================================================
# Main Script
# ==============================================================================

# Check if curl is available
if ! command -v curl &>/dev/null; then
  log_error "curl command not found"
  echo "Error: curl not found" >&2
  exit 1
fi

# Check if config file exists
if [[ ! -f "$SSH_CONFIG" ]]; then
  log_error "Config file not found: $SSH_CONFIG"
  echo "Error: Config file not found: $SSH_CONFIG" >&2
  exit 1
fi

debug_msg "Reading SSH key URLs from: $SSH_CONFIG"

total=0
added=0
duplicate=0
failed=0

# Read config file and process each URL
while IFS= read -r url || [[ -n "$url" ]]; do
  # Skip empty lines and comments
  [[ -z "$url" || "$url" =~ ^[[:space:]]*# ]] && continue

  # Trim whitespace
  url=$(echo "$url" | xargs)

  ((total++))

  debug_msg "Processing URL $total: $url"

  if ((DRY_RUN)); then
    info "[dry-run] Add key from: $url"
    ((added++))
    continue
  fi

  start_spinner

  # Download the key
  if ! key_content=$(download_key "$url"); then
    stop_spinner_fail
    log_error "Failed to download: $url"
    echo "[✗] Failed to download: $url" >&2
    ((failed++))
    continue
  fi

  # Add key to authorized_keys
  if add_key_to_authorized_keys "$key_content" "$url"; then
    stop_spinner
    info "[✓] Added key from: $url"
    ((added++))
  elif [[ $? -eq 2 ]]; then
    stop_spinner
    info "[≈] Key already exists: $url"
    ((duplicate++))
  else
    stop_spinner_fail
    log_error "Failed to add key from: $url"
    echo "[✗] Failed to add key from: $url" >&2
    ((failed++))
  fi
done <"$SSH_CONFIG"

# Fix permissions on authorized_keys
if [[ -f "$AUTHORIZED_KEYS" ]]; then
  chmod 600 "$AUTHORIZED_KEYS" 2>/dev/null || true
fi

# Summary
info ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "SSH Key Management Summary"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "Total URLs:    $total"
info "Keys Added:    $added"
info "Duplicates:    $duplicate"
info "Failed:        $failed"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ((failed > 0)); then
  log_error "One or more SSH key URLs failed during processing"
  echo "Check $LOG_FILE for details on failures" >&2
  exit 1
fi

info "SSH post hook complete."

exit 0
