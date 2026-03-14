#!/usr/bin/env bash
set -euo pipefail

# Configure OpenPGP touch policy on YubiKey.
# Defaults to requiring touch for signature, decryption and authentication keys.

SCRIPT_NAME=$(basename "$0")

DEFAULT_POLICY="on"
SIG_POLICY=""
DEC_POLICY=""
AUT_POLICY=""
FORCE=0

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Configure YubiKey OpenPGP touch policy.

Options:
  -p, --policy POLICY   Policy for all key slots (default: on)
  --sig POLICY          Signature slot policy override
  --dec POLICY          Decryption slot policy override
  --aut POLICY          Authentication slot policy override
  -f, --force           Skip confirmation prompt
  -h, --help            Show this help text

Valid policies:
  on, off, fixed, cached, cached-fixed

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --policy cached
  ${SCRIPT_NAME} --sig on --dec cached --aut on
EOF
}

print_error() {
  echo "Error: $*" >&2
}

require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || {
    print_error "Required command not found: $cmd"
    exit 1
  }
}

validate_policy() {
  local policy="$1"
  case "$policy" in
    on|off|fixed|cached|cached-fixed) ;;
    *)
      print_error "Invalid policy: $policy"
      print_error "Valid policies: on, off, fixed, cached, cached-fixed"
      exit 1
      ;;
  esac
}

has_yubikey() {
  ykman list 2>/dev/null | grep -qi "yubikey"
}

# Try command variants for compatibility across ykman versions.
set_touch_policy() {
  local slot="$1"
  local policy="$2"

  if ykman openpgp keys set-touch "$slot" "$policy" >/dev/null 2>&1; then
    return 0
  fi

  # Older ykman versions used 'enc' instead of 'dec'.
  if [[ "$slot" == "dec" ]]; then
    if ykman openpgp keys set-touch enc "$policy" >/dev/null 2>&1; then
      return 0
    fi
  fi

  # Even older ykman versions used 'touch' instead of 'set-touch'.
  if ykman openpgp keys touch "$slot" "$policy" >/dev/null 2>&1; then
    return 0
  fi

  if [[ "$slot" == "dec" ]]; then
    if ykman openpgp keys touch enc "$policy" >/dev/null 2>&1; then
      return 0
    fi
  fi

  return 1
}

confirm_plan() {
  echo
  echo "About to configure YubiKey OpenPGP touch policy:"
  echo "  sig: ${SIG_POLICY}"
  echo "  dec: ${DEC_POLICY}"
  echo "  aut: ${AUT_POLICY}"
  echo
  read -r -p "Continue? [y/N] " reply
  case "$reply" in
    y|Y|yes|YES) ;;
    *)
      echo "Cancelled."
      exit 0
      ;;
  esac
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--policy)
        [[ $# -ge 2 ]] || { print_error "Missing value for $1"; exit 1; }
        DEFAULT_POLICY="$2"
        shift 2
        ;;
      --sig)
        [[ $# -ge 2 ]] || { print_error "Missing value for $1"; exit 1; }
        SIG_POLICY="$2"
        shift 2
        ;;
      --dec)
        [[ $# -ge 2 ]] || { print_error "Missing value for $1"; exit 1; }
        DEC_POLICY="$2"
        shift 2
        ;;
      --aut)
        [[ $# -ge 2 ]] || { print_error "Missing value for $1"; exit 1; }
        AUT_POLICY="$2"
        shift 2
        ;;
      -f|--force)
        FORCE=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done
}

main() {
  parse_args "$@"

  require_command ykman

  if ! has_yubikey; then
    print_error "No YubiKey detected. Insert a YubiKey and try again."
    exit 1
  fi

  SIG_POLICY=${SIG_POLICY:-$DEFAULT_POLICY}
  DEC_POLICY=${DEC_POLICY:-$DEFAULT_POLICY}
  AUT_POLICY=${AUT_POLICY:-$DEFAULT_POLICY}

  validate_policy "$SIG_POLICY"
  validate_policy "$DEC_POLICY"
  validate_policy "$AUT_POLICY"

  if [[ "$FORCE" -eq 0 ]]; then
    confirm_plan
  fi

  echo "Setting touch policy for signature key (sig) to '${SIG_POLICY}'..."
  set_touch_policy sig "$SIG_POLICY" || {
    print_error "Failed to set touch policy for sig"
    exit 1
  }

  echo "Setting touch policy for decryption key (dec/enc) to '${DEC_POLICY}'..."
  set_touch_policy dec "$DEC_POLICY" || {
    print_error "Failed to set touch policy for dec/enc"
    exit 1
  }

  echo "Setting touch policy for authentication key (aut) to '${AUT_POLICY}'..."
  set_touch_policy aut "$AUT_POLICY" || {
    print_error "Failed to set touch policy for aut"
    exit 1
  }

  echo
  echo "Touch policy updated. Current OpenPGP key settings:"
  ykman openpgp keys info || {
    print_error "Could not read key info. Try: ykman openpgp keys set-touch -h"
    exit 1
  }
}

main "$@"
