#!/usr/bin/env bash
#
# YubiKey OpenPGP Setup Script
# Implements an optional-step workflow for managing encrypted key material on /mnt/master.

set -euo pipefail

# ============================================================================
# Display helpers
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
}

print_step() {
    echo -e "${GREEN}->${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC}  $1"
}

print_error() {
    echo -e "${RED}x${NC}  $1"
}

pause_for_menu() {
    echo
    read -r -p "Press Enter to return to menu..." _
}

prompt_yes_no() {
    local prompt="$1"
    local response
    read -r -p "$prompt [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]]
}

prompt_hidden() {
    local prompt="$1"
    local value=""
    read -r -s -p "$prompt" value
    printf '\n' >&2
    printf '%s' "$value"
}

# ============================================================================
# Global state
# ============================================================================

readonly MASTER_MOUNT="/mnt/master"
readonly MASTER_MAPPER="/dev/mapper/master"
readonly SESSION_STAMP="${SESSION_STAMP:-$(date +%Y%m%d-%H%M%S)}"

GNUPGHOME="${GNUPGHOME:-}"
KEYID="${KEYID:-}"
KEYFP="${KEYFP:-}"
IDENTITY="${IDENTITY:-}"
KEY_TYPE="${KEY_TYPE:-rsa4096}"
EXPIRATION="${EXPIRATION:-2y}"
CERTIFY_PASS="${CERTIFY_PASS:-}"
ADMIN_PIN="${ADMIN_PIN:-}"
USER_PIN="${USER_PIN:-}"
RESET_PIN="${RESET_PIN:-}"

# Track temporary directories created under /mnt/master so trap can clean up safely.
declare -a TEMP_DIRS=()
CLEANUP_DONE=0

# ============================================================================
# Trap and cleanup
# ============================================================================

cleanup_temp_dirs() {
    local dir
    for dir in "${TEMP_DIRS[@]:-}"; do
        [[ -z "$dir" ]] && continue
        [[ ! -d "$dir" ]] && continue

        # Guardrails: never delete key homes or backups.
        if [[ -n "${KEYID:-}" ]]; then
            if [[ "$dir" == "$MASTER_MOUNT/$KEYID" || "$dir" == "$MASTER_MOUNT/$KEYID-BACKUP" ]]; then
                continue
            fi
        fi

        if [[ "$dir" == "$MASTER_MOUNT"/* ]]; then
            rm -rf -- "$dir"
        fi
    done
}

on_exit() {
    local rc=$?
    if [[ "$CLEANUP_DONE" -eq 0 ]]; then
        cleanup_temp_dirs
        CLEANUP_DONE=1
    fi

    if [[ $rc -eq 130 ]]; then
        print_warning "Interrupted by user"
    fi

    if [[ $rc -eq 143 ]]; then
        print_warning "Terminated by signal"
    fi

    if [[ $rc -eq 129 ]]; then
        print_warning "Hangup signal received"
    fi

    if [[ $rc -ne 0 ]]; then
        print_error "Script exited with error status $rc"
    fi
}

on_signal() {
    local sig="$1"
    print_warning "Received signal $sig; cleaning up before exit"

    if [[ "$CLEANUP_DONE" -eq 0 ]]; then
        cleanup_temp_dirs
        CLEANUP_DONE=1
    fi

    case "$sig" in
        INT) exit 130 ;;
        TERM) exit 143 ;;
        HUP) exit 129 ;;
        *) exit 1 ;;
    esac
}

trap 'on_signal INT' INT
trap 'on_signal TERM' TERM
trap 'on_signal HUP' HUP
trap on_exit EXIT

# ============================================================================
# Core helpers
# ============================================================================

ensure_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        print_error "Required command not found: $cmd"
        return 1
    fi
}

is_master_mounted() {
    mountpoint -q "$MASTER_MOUNT"
}

detect_luks_devices() {
    lsblk -lf | awk '$2 == "crypto_LUKS" {print $1, $NF}'
}

resolve_first_luks_device() {
    local line dev
    line=$(detect_luks_devices | head -n 1 || true)
    dev=$(awk '{print $1}' <<<"$line")
    [[ -n "$dev" ]] || return 1
    if [[ "$dev" == /dev/* ]]; then
        printf '%s' "$dev"
    else
        printf '/dev/%s' "$dev"
    fi
}

ensure_gnupghome_env() {
    export GNUPGHOME
    mkdir -p "$GNUPGHOME"
    chmod 700 "$GNUPGHOME" || true
}

load_key_identity_from_gnupg() {
    local out
    out=$(gpg --list-secret-keys --with-colons 2>/dev/null || true)
    KEYID=$(awk -F: '$1 == "sec" {print $5; exit}' <<<"$out")
    KEYFP=$(awk -F: '$1 == "fpr" {print $10; exit}' <<<"$out")
    export KEYID KEYFP
}

choose_existing_key_home() {
    local -a homes=()
    local i choice

    while IFS= read -r line; do
        homes+=("$line")
    done < <(find "$MASTER_MOUNT" -mindepth 2 -maxdepth 2 -type d -name .gnupg 2>/dev/null | sort)

    if [[ ${#homes[@]} -eq 0 ]]; then
        return 1
    fi

    if [[ ${#homes[@]} -eq 1 ]]; then
        GNUPGHOME="${homes[0]}"
        KEYID=$(basename "$(dirname "$GNUPGHOME")")
        export GNUPGHOME KEYID
        return 0
    fi

    print_step "Multiple key homes found on $MASTER_MOUNT"
    for i in "${!homes[@]}"; do
        printf '  %d) %s\n' "$((i + 1))" "${homes[$i]}"
    done
    read -r -p "Select key home number: " choice

    if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#homes[@]} )); then
        print_error "Invalid selection"
        return 1
    fi

    GNUPGHOME="${homes[$((choice - 1))]}"
    KEYID=$(basename "$(dirname "$GNUPGHOME")")
    export GNUPGHOME KEYID
    return 0
}

prepare_gnupghome() {
    print_step "Preparing GNUPGHOME"
    mount_encrypted_master_flash_drive

    if choose_existing_key_home; then
        print_step "Using existing GNUPGHOME: $GNUPGHOME"
    else
        local session_root
        session_root="$MASTER_MOUNT/$SESSION_STAMP"
        GNUPGHOME="$session_root/.gnupg"

        if [[ ! -d "$GNUPGHOME" ]]; then
            mkdir -p "$GNUPGHOME"
            TEMP_DIRS+=("$session_root")
            print_step "No existing key home found; created session GNUPGHOME: $GNUPGHOME"
        else
            print_step "No existing key home found; reusing session GNUPGHOME: $GNUPGHOME"
        fi
    fi

    ensure_gnupghome_env
    load_key_identity_from_gnupg

    if [[ -n "$KEYID" ]]; then
        print_step "Current key context: $KEYID"
    fi
}

prompt_certify_passphrase() {
    if [[ -n "$CERTIFY_PASS" ]]; then
        return 0
    fi

    local one two
    while true; do
        one=$(prompt_hidden "Enter Certify passphrase: ")
        [[ -n "$one" ]] || { print_error "Passphrase cannot be empty"; continue; }
        two=$(prompt_hidden "Confirm Certify passphrase: ")
        if [[ "$one" == "$two" ]]; then
            CERTIFY_PASS="$one"
            export CERTIFY_PASS
            return 0
        fi
        print_error "Passphrases do not match"
    done
}

prompt_admin_pin() {
    if [[ -n "$ADMIN_PIN" ]]; then
        return 0
    fi
    ADMIN_PIN=$(prompt_hidden "Enter Admin PIN (default 12345678): ")
    ADMIN_PIN=${ADMIN_PIN:-12345678}
    export ADMIN_PIN
}

get_subkey_number_by_capability() {
    local cap="$1"
    gpg --list-secret-keys --with-colons "$KEYID" 2>/dev/null | \
        awk -F: -v c="$cap" '
            $1 == "ssb" {n++; if (index(tolower($12), tolower(c)) > 0) hit = n}
            END {if (hit > 0) print hit}
        '
}

has_subkey_capability() {
    local cap="$1"
    local found
    found=$(gpg --list-secret-keys --with-colons "$KEYID" 2>/dev/null | \
        awk -F: -v c="$cap" '
            $1 == "ssb" && index(tolower($12), tolower(c)) > 0 {print "yes"; exit}
        ')
    [[ "$found" == "yes" ]]
}

move_subkey_to_card() {
    local cap="$1"
    local slot="$2"
    local subkey_no
    local gpg_output

    subkey_no=$(get_subkey_number_by_capability "$cap")
    if [[ -z "$subkey_no" ]]; then
        print_error "Could not find a subkey with capability '$cap'"
        return 1
    fi

    prompt_certify_passphrase
    prompt_admin_pin

    gpg_output=$(gpg --command-fd=0 --pinentry-mode=loopback --edit-key "$KEYID" 2>&1 <<EOF
key $subkey_no
keytocard
$slot
$CERTIFY_PASS
$ADMIN_PIN
save
EOF
)

    if grep -Eqi 'KEYTOCARD failed|Bad PIN|gpg:.*failed|gpg:.*error' <<<"$gpg_output"; then
        print_error "Failed to move subkey ($cap) to YubiKey slot $slot"
        echo "$gpg_output"
        return 1
    fi

    print_step "Moved subkey ($cap) to YubiKey slot $slot"
}

run_step() {
    local label="$1"
    shift

    set +e
    "$@"
    local rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        print_warning "$label failed (exit $rc)"
    fi

    pause_for_menu
}

# ============================================================================
# Step 1: Mount Encrypted Master Flash Drive
# ============================================================================

mount_encrypted_master_flash_drive() {
    print_header "1) Mount Encrypted Master Flash Drive"

    ensure_command lsblk
    ensure_command cryptsetup

    if is_master_mounted; then
        print_step "$MASTER_MOUNT is already mounted"
        return 0
    fi

    local luks_device
    luks_device=$(resolve_first_luks_device || true)
    if [[ -z "$luks_device" ]]; then
        print_error "No crypto_LUKS device found via: lsblk -lf | grep crypto_LUKS"
        return 1
    fi

    print_step "Detected LUKS device: $luks_device"
    sudo cryptsetup luksOpen "$luks_device" master
    sudo mkdir -p "$MASTER_MOUNT"
    sudo mount "$MASTER_MAPPER" "$MASTER_MOUNT"
    sudo chown -R "$USER:$USER" "$MASTER_MOUNT"

    print_step "Mounted encrypted drive at $MASTER_MOUNT"
}

# ============================================================================
# Step 2: Unmount Encrypted Master Flash Drive
# ============================================================================

unmount_encrypted_master_flash_drive() {
    print_header "2) Unmount Encrypted Master Flash Drive"

    if ! is_master_mounted; then
        print_step "$MASTER_MOUNT is not mounted"
        return 0
    fi

    sudo umount "$MASTER_MOUNT"
    sudo cryptsetup luksClose master
    print_step "Unmounted and closed encrypted drive"
}

# ============================================================================
# Step 3: Check YubiKey
# ============================================================================

check_yubikey() {
    print_header "3) Check YubiKey"

    ensure_command gpg

    until gpg --card-status >/dev/null 2>&1; do
        print_warning "YubiKey not detected. Insert the YubiKey, then press Enter to retry."
        read -r _
    done

    print_step "YubiKey detected"
    gpg --command-fd=0 --pinentry-mode=loopback --card-edit <<EOF
quit
EOF
}

# ============================================================================
# Step 4: Reset OpenPGP
# ============================================================================

enable_kdf() {
    prompt_admin_pin
    print_step "Enabling OpenPGP KDF"

    gpg --command-fd=0 --pinentry-mode=loopback --card-edit <<EOF
admin
kdf-setup
$ADMIN_PIN
quit
EOF
}

reset_openpgp() {
    print_header "4) Reset OpenPGP"

    ensure_command ykman

    check_yubikey

    print_warning "Resetting OpenPGP applet clears all OpenPGP keys and OpenPGP PIN data on the YubiKey."
    if ! prompt_yes_no "Continue with OpenPGP reset?"; then
        print_step "OpenPGP reset cancelled"
        return 0
    fi

    if ! ykman reset openpgp; then
        print_warning "'ykman reset openpgp' failed; trying 'ykman openpgp reset --force'"
        ykman openpgp reset --force
    fi

    print_step "OpenPGP applet reset complete"
    enable_kdf
}

# ============================================================================
# Step 5: Create Primary Key (Certify)
# ============================================================================

create_primary_key_certify() {
    print_header "5) Create Primary Key (Certify)"

    prepare_gnupghome

    local create_key="false"

    if gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '$1 == "sec" {found=1} END {exit(found?0:1)}'; then
        if prompt_yes_no "Certify key exists. Create another key?"; then
            create_key="true"
        fi
    else
        create_key="true"
    fi

    if [[ "$create_key" != "true" ]]; then
        print_step "Keeping existing key set in $GNUPGHOME"
        load_key_identity_from_gnupg
        return 0
    fi

    prompt_certify_passphrase

    read -r -p "Identity (Name <email>): " IDENTITY
    [[ -n "$IDENTITY" ]] || { print_error "Identity is required"; return 1; }

    read -r -p "Key type [rsa4096]: " KEY_TYPE
    KEY_TYPE=${KEY_TYPE:-rsa4096}

    read -r -p "Master key expiration [never]: " EXPIRATION
    EXPIRATION=${EXPIRATION:-never}

    export IDENTITY KEY_TYPE EXPIRATION

    print_step "Creating primary certify key"
    printf '%s' "$CERTIFY_PASS" | \
        gpg --batch --pinentry-mode=loopback --passphrase-fd 0 \
            --quick-generate-key "$IDENTITY" "$KEY_TYPE" cert "$EXPIRATION"

    load_key_identity_from_gnupg

    if [[ -z "$KEYID" ]]; then
        print_error "Failed to determine KEYID after key creation"
        return 1
    fi

    local current_root
    local final_root

    current_root=$(dirname "$GNUPGHOME")
    final_root="$MASTER_MOUNT/$KEYID"

    if [[ "$current_root" != "$final_root" ]]; then
        mkdir -p "$final_root"
        if [[ -d "$final_root/.gnupg" ]]; then
            print_warning "Target exists: $final_root/.gnupg; keeping current GNUPGHOME"
        else
            mv "$GNUPGHOME" "$final_root/.gnupg"
            GNUPGHOME="$final_root/.gnupg"
            export GNUPGHOME

            # Remove temp root from cleanup list, now persisted as key root.
            local i
            for i in "${!TEMP_DIRS[@]}"; do
                if [[ "${TEMP_DIRS[$i]}" == "$current_root" ]]; then
                    unset 'TEMP_DIRS[i]'
                    break
                fi
            done
        fi
    fi

    print_step "Setting ultimate trust on primary key"
    echo -e "5\ny\n" | gpg --command-fd=0 --batch --edit-key "$KEYID" trust quit >/dev/null 2>&1

    print_step "Primary key ready"
    print_step "KEYID: $KEYID"
    print_step "GNUPGHOME: $GNUPGHOME"
}

# ============================================================================
# Step 6: Create Subkeys
# ============================================================================

create_subkeys() {
    print_header "6) Create Subkeys"

    create_primary_key_certify

    prompt_admin_pin

    local type_input
    local subtypes

    read -r -p "Subkey type(s) [sign,encrypt,auth,all] (comma-separated): " type_input
    type_input=${type_input:-all}

    if [[ "$type_input" == "all" ]]; then
        subtypes="sign encrypt auth"
    else
        subtypes=$(tr ',' ' ' <<<"$type_input")
    fi

    local subtype expiration cap slot
    local create_new_subkey
    local valid_subtypes=""
    local transfer_requested="no"

    # Phase 1: Create any requested subkeys first.
    for subtype in $subtypes; do
        case "$subtype" in
            sign)
                cap="s"
                slot="1"
                ;;
            encrypt)
                cap="e"
                slot="2"
                ;;
            auth)
                cap="a"
                slot="3"
                ;;
            *)
                print_warning "Skipping unknown subkey type: $subtype"
                continue
                ;;
        esac

        valid_subtypes+="$subtype "

        read -r -p "Expiration for $subtype subkey [${EXPIRATION:-2y}]: " expiration
        expiration=${expiration:-${EXPIRATION:-2y}}

        create_new_subkey="yes"
        if has_subkey_capability "$cap"; then
            if ! prompt_yes_no "A $subtype-capable subkey already exists. Create another?"; then
                create_new_subkey="no"
                print_step "Keeping existing $subtype-capable subkey"
            fi
        fi

        if [[ "$create_new_subkey" == "yes" ]]; then
            prompt_certify_passphrase
            print_step "Creating $subtype subkey"
            printf '%s' "$CERTIFY_PASS" | \
                gpg --batch --pinentry-mode=loopback --passphrase-fd 0 \
                    --quick-add-key "$KEYFP" "$KEY_TYPE" "$subtype" "$expiration"
        fi
    done

    # Phase 2: Offer backup before any transfer occurs.
    if [[ -z "${valid_subtypes// }" ]]; then
        print_warning "No valid subkey types selected"
        print_step "Subkey workflow complete"
        return 0
    fi

    if prompt_yes_no "Transfer subkeys to YubiKey now?"; then
        transfer_requested="yes"

        print_warning "After transfer to card, only key stubs remain locally."
        if prompt_yes_no "Create a backup now before any transfer?"; then
            backup_existing_keys || {
                print_error "Backup failed; skipping all transfers"
                print_step "Subkey workflow complete"
                return 1
            }
        else
            print_warning "Continuing without backup at user request"
        fi
    fi

    # Phase 3: Offer transfer for each selected subkey.
    if [[ "$transfer_requested" == "yes" ]]; then
        check_yubikey

        for subtype in $valid_subtypes; do
            case "$subtype" in
                sign)
                    cap="s"
                    slot="1"
                    ;;
                encrypt)
                    cap="e"
                    slot="2"
                    ;;
                auth)
                    cap="a"
                    slot="3"
                    ;;
                *)
                    continue
                    ;;
            esac

            if ! has_subkey_capability "$cap"; then
                print_warning "No $subtype-capable subkey found; skipping transfer prompt"
                continue
            fi

            if prompt_yes_no "Move $subtype subkey to YubiKey (overwrites existing slot key)?"; then
                move_subkey_to_card "$cap" "$slot"
            fi
        done
    fi

    print_step "Subkey workflow complete"
}

# ============================================================================
# Step 7: Reset PINs
# ============================================================================

set_user_pin() {
    local current_pin new_pin confirm_pin
    current_pin=$(prompt_hidden "Current User PIN: ")
    new_pin=$(prompt_hidden "New User PIN: ")
    confirm_pin=$(prompt_hidden "Confirm New User PIN: ")

    [[ "$new_pin" == "$confirm_pin" ]] || { print_error "PIN confirmation mismatch"; return 1; }

    gpg --command-fd=0 --pinentry-mode=loopback --change-pin <<EOF
1
$current_pin
$new_pin
$new_pin
q
EOF

    USER_PIN="$new_pin"
    export USER_PIN
}

set_admin_pin() {
    local current_pin new_pin confirm_pin
    current_pin=$(prompt_hidden "Current Admin PIN: ")
    new_pin=$(prompt_hidden "New Admin PIN: ")
    confirm_pin=$(prompt_hidden "Confirm New Admin PIN: ")

    [[ "$new_pin" == "$confirm_pin" ]] || { print_error "PIN confirmation mismatch"; return 1; }

    gpg --command-fd=0 --pinentry-mode=loopback --change-pin <<EOF
3
$current_pin
$new_pin
$new_pin
q
EOF

    ADMIN_PIN="$new_pin"
    export ADMIN_PIN
}

set_reset_pin() {
    local admin_pin new_pin confirm_pin
    admin_pin=$(prompt_hidden "Admin PIN: ")
    new_pin=$(prompt_hidden "New Reset PIN: ")
    confirm_pin=$(prompt_hidden "Confirm New Reset PIN: ")

    [[ "$new_pin" == "$confirm_pin" ]] || { print_error "PIN confirmation mismatch"; return 1; }

    gpg --command-fd=0 --pinentry-mode=loopback --change-pin <<EOF
4
$admin_pin
$new_pin
$new_pin
q
EOF

    RESET_PIN="$new_pin"
    export RESET_PIN
}

reset_pins() {
    print_header "7) Reset PINs"

    check_yubikey

    local choice
    while true; do
        echo "Pin to Change:"
        echo "  1) admin"
        echo "  2) user"
        echo "  3) reset"
        echo "  b) back to main menu"
        read -r -p "Select option: " choice

        case "$choice" in
            1|admin)
                set_admin_pin
                ;;
            2|user)
                set_user_pin
                ;;
            3|reset)
                set_reset_pin
                ;;
            b|B|back)
                break
                ;;
            *)
                print_error "Invalid selection"
                continue
                ;;
        esac

        if ! prompt_yes_no "Change another PIN?"; then
            break
        fi
    done
}

# ============================================================================
# Step 8: Backup Existing Keys
# ============================================================================

backup_existing_keys() {
    print_header "8) Backup Existing Keys"

    mount_encrypted_master_flash_drive

    if [[ -z "${KEYID:-}" ]]; then
        if choose_existing_key_home; then
            KEYID=$(basename "$(dirname "$GNUPGHOME")")
            export KEYID
        else
            print_error "KEYID is not known and no existing key home was selected"
            return 1
        fi
    fi

    local src="$MASTER_MOUNT/$KEYID"
    local dst="$MASTER_MOUNT/$KEYID-BACKUP"

    if [[ ! -d "$src" ]]; then
        print_error "Source key directory not found: $src"
        return 1
    fi

    if [[ -e "$dst" ]]; then
        if ! prompt_yes_no "Backup target exists ($dst). Replace it?"; then
            print_step "Backup cancelled"
            return 0
        fi
        rm -rf -- "$dst"
    fi

    cp -a "$src" "$dst"
    print_step "Backup created: $dst"
}

# ============================================================================
# Step 9: Upload to Keyserver
# ============================================================================

upload_to_keyserver() {
    print_header "9) Upload to Keyserver"

    ensure_command gpg

    if [[ -z "${GNUPGHOME:-}" || -z "${KEYID:-}" ]]; then
        mount_encrypted_master_flash_drive
        if ! choose_existing_key_home; then
            print_error "No key home found under $MASTER_MOUNT"
            return 1
        fi
        ensure_gnupghome_env
        load_key_identity_from_gnupg
    fi

    if [[ -z "${KEYID:-}" ]]; then
        print_error "Could not determine KEYID for upload"
        return 1
    fi

    local keyserver
    read -r -p "Keyserver [hkps://keys.openpgp.org]: " keyserver
    keyserver=${keyserver:-hkps://keys.openpgp.org}

    print_step "Uploading public key $KEYID to $keyserver"
    gpg --keyserver "$keyserver" --send-keys "$KEYID"
    print_step "Upload request sent"
}

export_public_key() {
    print_header "10) Export Public Key"

    ensure_command gpg

    if [[ -z "${GNUPGHOME:-}" || -z "${KEYID:-}" ]]; then
        mount_encrypted_master_flash_drive
        if ! choose_existing_key_home; then
            print_error "No key home found under $MASTER_MOUNT"
            return 1
        fi
        ensure_gnupghome_env
        load_key_identity_from_gnupg
    fi

    if [[ -z "${KEYID:-}" ]]; then
        print_error "Could not determine KEYID for export"
        return 1
    fi

    local output_file
    local default_file="$MASTER_MOUNT/${KEYID}.asc"
    read -r -p "Output file [$default_file]: " output_file
    output_file=${output_file:-$default_file}

    if [[ -f "$output_file" ]]; then
        if ! prompt_yes_no "File exists. Overwrite $output_file?"; then
            print_step "Export cancelled"
            return 0
        fi
    fi

    print_step "Exporting public key $KEYID to $output_file"
    if gpg --armor --export "$KEYID" > "$output_file"; then
        print_step "Public key exported successfully"
        print_step "File: $output_file"
    else
        print_error "Failed to export public key"
        return 1
    fi
}

set_yubikey_attributes() {
    print_header "11) Set YubiKey Attributes"

    ensure_command gpg
    ensure_command ykman

    if ! ykman list 2>/dev/null | grep -q YubiKey; then
        print_error "No YubiKey detected"
        return 1
    fi

    print_step "Current card status:"
    gpg --card-status 2>/dev/null | grep -E "^(Name|Login|Language|URL)"
    echo

    print_step "Enter YubiKey cardholder attributes (all optional, press Enter to skip)"
    echo

    local name lastname firstname login lang url
    local commands=""

    # Prompt for attributes
    read -r -p "Full Name (First Last): " name
    if [[ -n "$name" ]]; then
        # Parse into first and last name
        firstname="${name##* }"
        lastname="${name% *}"
        if [[ "$firstname" == "$lastname" ]]; then
            # Single name provided
            firstname="$name"
            lastname=""
        fi
    fi

    read -r -p "Username/Login [${USER}]: " login
    login=${login:-${USER}}

    read -r -p "Language [en]: " lang
    lang=${lang:-en}

    read -r -p "URL: " url

    # Build command sequence
    if [[ -n "$lastname" || -n "$firstname" ]]; then
        commands+="admin\nname\n${lastname}\n${firstname}\n"
    fi

    if [[ -n "$login" ]]; then
        commands+="admin\nlogin\n${login}\n"
    fi

    if [[ -n "$lang" ]]; then
        commands+="admin\nlang\n${lang}\n"
    fi

    if [[ -n "$url" ]]; then
        commands+="admin\nurl\n${url}\n"
    fi

    if [[ -z "$commands" ]]; then
        print_step "No attributes to set"
        return 0
    fi

    commands+="quit\n"

    print_step "Setting YubiKey attributes..."
    echo -e "${commands}" | gpg --command-fd=0 --card-edit >/dev/null 2>&1

    print_step "Attributes set successfully"
    echo
    print_step "Updated card status:"
    gpg --card-status 2>/dev/null | grep -E "^(Name|Login|Language|URL)"
}

# ============================================================================
# Main menu
# ============================================================================

show_menu() {
    clear
    echo
    echo -e "${BLUE}YubiKey OpenPGP Setup${NC}"
    echo "Some steps are optional and can be run independently."
    echo
    echo "  1) Mount Encrypted Master Flash Drive"
    echo "  2) Unmount Encrypted Master Flash Drive"
    echo "  3) Check YubiKey"
    echo "  4) Reset OpenPGP"
    echo "  5) Create Primary Key (Certify)"
    echo "  6) Create Subkeys"
    echo "  7) Reset PINs"
    echo "  8) Backup Existing Keys"
    echo "  9) Upload to keyserver"
    echo "  10) Export Public Key"
    echo "  11) Set YubiKey Attributes"
    echo "  12) Quit"
    echo
}

main() {
    local choice

    while true; do
        show_menu
        read -r -p "Select step: " choice

        case "$choice" in
            1)
                run_step "Mount Encrypted Master Flash Drive" mount_encrypted_master_flash_drive
                ;;
            2)
                run_step "Unmount Encrypted Master Flash Drive" unmount_encrypted_master_flash_drive
                ;;
            3)
                run_step "Check YubiKey" check_yubikey
                ;;
            4)
                run_step "Reset OpenPGP" reset_openpgp
                ;;
            5)
                run_step "Create Primary Key (Certify)" create_primary_key_certify
                ;;
            6)
                run_step "Create Subkeys" create_subkeys
                ;;
            7)
                run_step "Reset PINs" reset_pins
                ;;
            8)
                run_step "Backup Existing Keys" backup_existing_keys
                ;;
            9)
                run_step "Upload to keyserver" upload_to_keyserver
                ;;
            10)
                run_step "Export Public Key" export_public_key
                ;;
            11)
                run_step "Set YubiKey Attributes" set_yubikey_attributes
                ;;
            12|q|Q)
                print_step "Exiting: attempting to unmount encrypted master drive"
                if ! unmount_encrypted_master_flash_drive; then
                    print_warning "Could not unmount encrypted master drive during quit"
                fi
                break
                ;;
            *)
                print_error "Invalid selection"
                pause_for_menu
                ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main
fi
