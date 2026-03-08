#!/bin/bash
set -euo pipefail

# OpenPGP Key Transition Statement Generator
# This script generates and signs a key transition statement when moving to a new GPG key

# Configuration - can be overridden via environment variables
FULL_NAME="${FULL_NAME:-Mark Faine}"
FIRST_NAME="${FIRST_NAME:-Mark}"
URL="${URL:-https://markfaine.net}"
KEYSERVER="${KEYSERVER:-keys.openpgp.org}"
CONTACT_EMAIL="${CONTACT_EMAIL:-}"
OUTPUT_DIR="${OUTPUT_DIR:-.}"
VERBOSE="${VERBOSE:-0}"

# Script state
SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
effective=$(date +%Y-%m-%d)
TEMP_FILE=""

# Cleanup function
cleanup() {
  if [[ -n "${TEMP_FILE}" && -f "${TEMP_FILE}" ]]; then
    rm -f "${TEMP_FILE}"
  fi
}

trap cleanup EXIT INT TERM HUP

# Print usage information
usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS] <old-key-id> <new-key-id>

Generate and sign an OpenPGP key transition statement.

Arguments:
  old-key-id    The key ID or fingerprint of your old key
  new-key-id    The key ID or fingerprint of your new key

Options:
  -h, --help          Show this help message
  -o, --output DIR    Output directory (default: current directory)
  -u, --url URL       URL where key will be published (default: ${URL})
  -k, --keyserver SRV Keyserver to reference (default: ${KEYSERVER})
  -e, --email EMAIL   Contact email to include in statement
  -v, --verbose       Show verbose output
  -y, --yes           Skip confirmation prompt

Environment Variables:
  FULL_NAME      Your full name (default: ${FULL_NAME})
  FIRST_NAME     Your first name (default: ${FIRST_NAME})
  URL            Your website URL (default: ${URL})
  KEYSERVER      Keyserver to reference (default: ${KEYSERVER})
  CONTACT_EMAIL  Your contact email
  OUTPUT_DIR     Output directory (default: current)

Examples:
  ${SCRIPT_NAME} 0x1234ABCD 0x5678EF90
  ${SCRIPT_NAME} -o ~/keys -e me@example.com 0x1234ABCD 0x5678EF90
  ${SCRIPT_NAME} --yes oldkey newkey

EOF
  exit 0
}

# Print error message and exit
error() {
  echo "Error: $*" >&2
  exit 1
}

# Print verbose message
verbose() {
  if [[ "${VERBOSE}" == "1" ]]; then
    echo "$*" >&2
  fi
}

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Validate GPG key exists and can be used
validate_key() {
  local key_id="$1"
  local key_type="$2"

  verbose "Validating ${key_type} key: ${key_id}"

  if ! gpg --list-keys "${key_id}" >/dev/null 2>&1; then
    error "${key_type} key '${key_id}' not found in keyring"
  fi

  # Check if key has signing capability
  if ! gpg --list-keys --with-colons "${key_id}" 2>/dev/null | grep -q "^pub.*:[^:]*s"; then
    error "${key_type} key '${key_id}' does not have signing capability"
  fi

  # Check if key is expired
  local expiry
  expiry=$(gpg --list-keys --with-colons "${key_id}" 2>/dev/null | awk -F: '/^pub/ {print $7}')
  if [[ -n "${expiry}" && "${expiry}" != "0" ]]; then
    local now
    now=$(date +%s)
    if [[ "${expiry}" -lt "${now}" ]]; then
      error "${key_type} key '${key_id}' is expired"
    fi
  fi
}

# Get clean key fingerprint output
get_key_info() {
  local key_id="$1"
  gpg --fingerprint "${key_id}" 2>/dev/null | head -2 | sed 's/^[[:space:]]*//'
}

# Generate the transition statement
generate_statement() {
  local old_key="$1"
  local new_key="$2"
  local output_file="$3"

  verbose "Generating transition statement: ${output_file}"

  local old_key_info
  old_key_info=$(get_key_info "${old_key}")
  local new_key_info
  new_key_info=$(get_key_info "${new_key}")

  local email_section=""
  if [[ -n "${CONTACT_EMAIL}" ]]; then
    email_section="Or email ${CONTACT_EMAIL} (possibly encrypted) the output from:

  gpg --armor --export ${new_key}

"
  fi

  cat > "${output_file}" <<EOF
OpenPGP Key Transition Statement for ${FULL_NAME}

I have created a new OpenPGP key and will be transitioning away from
my old key. The old key has not been compromised and will continue to
be valid for some time, but I prefer all future correspondence to be
encrypted to the new key, and will be making signatures with the new
key going forward.

I would like this new key to be re-integrated into the web of trust.
This message is signed by both keys to certify the transition. My new
and old keys are signed by each other. If you have signed my old key,
I would appreciate signatures on my new key as well, provided that
your signing policy permits that without re-authenticating me.

The old key, which I am transitioning away from, is:

${old_key_info}

The new key, to which I am transitioning, is:

${new_key_info}

The entire key may be downloaded from: ${URL}/${new_key}.txt
To fetch the full new key from a public key server using GnuPG, run:

  gpg --keyserver ${KEYSERVER} --recv-key ${new_key}

If you already know my old key, you can now verify that the new key is
signed by the old one:

  gpg --check-sigs ${new_key}

If you are satisfied that you've got the right key, and the User IDs
match what you expect, I would appreciate it if you would sign my key:

  gpg --sign-key ${new_key}

You can upload your signatures to a public keyserver directly:

  gpg --keyserver ${KEYSERVER} --send-key ${new_key}

${email_section}If you'd like any further verification or have any questions about the
transition please contact me directly.

To verify the integrity of this statement:

  wget -q -O- ${URL}/key-transition-${effective}.txt | gpg --verify

Thanks,
-${FIRST_NAME}
EOF
}

# Sign the transition statement with both keys
sign_statement() {
  local unsigned_file="$1"
  local signed_file="$2"
  local old_key="$3"
  local new_key="$4"

  verbose "Signing statement with both keys..."

  if ! gpg --clearsign \
       --personal-digest-preferences SHA512 \
       --digest-algo SHA512 \
       --local-user "${old_key}" \
       --local-user "${new_key}!" \
       --output "${signed_file}" \
       "${unsigned_file}" 2>&1; then
    error "Failed to sign transition statement"
  fi

  verbose "Successfully signed: ${signed_file}"
}

# Main function
main() {
  local old_key_id=""
  local new_key_id=""
  local skip_confirm=0

  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        ;;
      -o|--output)
        OUTPUT_DIR="$2"
        shift 2
        ;;
      -u|--url)
        URL="$2"
        shift 2
        ;;
      -k|--keyserver)
        KEYSERVER="$2"
        shift 2
        ;;
      -e|--email)
        CONTACT_EMAIL="$2"
        shift 2
        ;;
      -v|--verbose)
        VERBOSE=1
        shift
        ;;
      -y|--yes)
        skip_confirm=1
        shift
        ;;
      -*)
        error "Unknown option: $1 (use --help for usage)"
        ;;
      *)
        if [[ -z "${old_key_id}" ]]; then
          old_key_id="$1"
        elif [[ -z "${new_key_id}" ]]; then
          new_key_id="$1"
        else
          error "Too many arguments (use --help for usage)"
        fi
        shift
        ;;
    esac
  done

  # Validate arguments
  if [[ -z "${old_key_id}" || -z "${new_key_id}" ]]; then
    echo "Error: Both old and new key IDs are required" >&2
    echo ""
    usage
  fi

  # Check prerequisites
  if ! command_exists gpg; then
    error "GPG is not installed or not in PATH"
  fi

  # Create output directory if needed
  if [[ ! -d "${OUTPUT_DIR}" ]]; then
    verbose "Creating output directory: ${OUTPUT_DIR}"
    mkdir -p "${OUTPUT_DIR}" || error "Failed to create output directory: ${OUTPUT_DIR}"
  fi

  # Validate both keys
  validate_key "${old_key_id}" "Old"
  validate_key "${new_key_id}" "New"

  # Set up file paths
  local unsigned_file="${OUTPUT_DIR}/key-transition-${effective}-unsigned.txt"
  local signed_file="${OUTPUT_DIR}/key-transition-${effective}.txt"
  TEMP_FILE="${unsigned_file}"

  # Check if output file exists
  if [[ -f "${signed_file}" ]]; then
    if [[ "${skip_confirm}" == "0" ]]; then
      echo "Output file already exists: ${signed_file}"
      read -p "Overwrite? [y/N] " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
      fi
    else
      verbose "Overwriting existing file: ${signed_file}"
    fi
  fi

  # Show summary and confirm
  if [[ "${skip_confirm}" == "0" ]]; then
    echo "Key Transition Statement Generator"
    echo "===================================="
    echo "Old Key: ${old_key_id}"
    echo "New Key: ${new_key_id}"
    echo "Date:    ${effective}"
    echo "Output:  ${signed_file}"
    echo ""
    read -p "Generate and sign transition statement? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
      echo "Aborted."
      exit 0
    fi
  fi

  # Generate the unsigned statement
  generate_statement "${old_key_id}" "${new_key_id}" "${unsigned_file}"

  # Sign the statement
  sign_statement "${unsigned_file}" "${signed_file}" "${old_key_id}" "${new_key_id}"

  # Clean up unsigned file
  rm -f "${unsigned_file}"
  TEMP_FILE=""

  # Success
  echo ""
  echo "✓ Successfully generated key transition statement:"
  echo "  ${signed_file}"
  echo ""
  echo "Next steps:"
  echo "  1. Review the signed statement: cat ${signed_file}"
  echo "  2. Publish to your website: ${URL}/key-transition-${effective}.txt"
  echo "  3. Distribute to keyservers and contacts"
  echo "  4. Update your key transition page"
}

main "$@"
